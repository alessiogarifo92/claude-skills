---
name: device-health
description: Use when the user asks to check, diagnose, speed up, clean or optimize their own devices - Samsung tablet SM-X230 and Xiaomi TV over adb, or the Windows PC - or says one of them is slow.
version: 1.0.0
---

# Device health check and optimization

**Run on:** main · effort low — read-only diagnostics plus reversible settings, run in the current session.

**Pairs with:** `handling-sudo-and-missing-tools` (ask before installing a missing tool such as adb), `direct-execution` (this is linear work, no subagents).

Devices: tablet (Samsung SM-X230, Android 16, 5.7 GB RAM), TV (Xiaomi MiTV-MZTU0, Android 14 / Google TV, 1.8 GB RAM, 4 GB storage), Windows 11 PC (this machine).
Another session may already be working on the TV: if the user says so, do not touch it.
Reply to the user in Italian. Run diagnostics first, report, then optimize. Ask before anything not reversible.

## adb (tablet and TV)

- adb: `C:\platform-tools\adb.exe`. If missing, download https://dl.google.com/android/repository/platform-tools-latest-windows.zip, extract into a new empty scratch folder, then move `platform-tools` to `C:\`.
- The tablet is already paired . Pairing is done once; it needs the pairing code and the pairing IP:port, which change every time the pairing screen is reopened.
- The connect port changes after every reboot and when Debug wireless is toggled. Find it with `adb mdns services` (entry `_adb-tls-connect._tcp`), then `adb connect IP:PORT`. If nothing is listed, ask the user to enable Settings -> Developer options -> Wireless debugging on the same Wi-Fi.
- Tablet IP seen so far: 192.168.1.21 (connect port random, from mdns).
- TV Xiaomi: IP 192.168.1.95, fixed adb port 5555 (`adb connect 192.168.1.95:5555`); mdns also lists a `_adb-tls-connect` port. Check `adb devices -l` first: it may already be connected. A stale entry marked `offline` (e.g. the tablet after a reboot) is just old; run `adb disconnect IP:PORT` and reconnect.
- Pairing is only needed for devices that do not show up in `adb devices` after Wireless debugging is on.
- Always target with `-s IP:PORT` when several devices are connected.
- Run each adb command as its own call or script; PowerShell breaks on `sed`/`grep` quoting inside `adb shell`, so filter output in PowerShell (`Select-String`) instead.

### Diagnose (read-only)

```
adb -s D shell "getprop ro.product.model; getprop ro.build.version.release"
adb -s D shell "grep -E 'MemTotal|MemAvailable|SwapFree' /proc/meminfo"
adb -s D shell "df -h /data | tail -1"
adb -s D shell uptime                       # long uptime + load >> cores = reboot needed
adb -s D shell "top -b -n 1 | head -5"      # tasks, CPU
adb -s D shell "dumpsys meminfo"            # 'Total PSS by process' = top RAM users
adb -s D shell "dumpsys battery"            # level, temperature (tenths of C)
adb -s D shell "pm list packages -3"        # third-party apps
adb -s D shell "pm list packages -d"        # disabled apps
```

Last-used date per app: parse `dumpsys usagestats` lines `package=X totalTimeUsed="..." lastTimeUsed="..."`, keep the max lastTimeUsed per package. 1970-01-01 means never used.

### Optimize (safe, reversible)

1. `pm trim-caches 4G`
2. Animations 0.5x: `settings put global window_animation_scale 0.5` (also `transition_animation_scale`, `animator_duration_scale`).
3. `cmd package bg-dexopt-job` (can take over 3 minutes: run in background).
4. `am kill-all`.
5. Unused apps: propose a list (not used for 3+ months or never used, no system or essential apps) and get the user's OK, then `pm disable-user --user 0 PACKAGE`. Undo with `pm enable PACKAGE`. Never disable Samsung/Google core, launcher, keyboard, Play Store/Services, banking/DigiD/authenticator apps.
6. Tell the user to reboot if uptime is more than a few days. Wireless debugging drops after reboot, so ask them to re-enable it before re-checking.

Known quirk: apps with `enabled=4` in `dumpsys package` are already dormant (disabled until used); `pm disable-user` fails on them with "Shell cannot change component state for null". They use no RAM; skip them.

Baseline from 2026-11-26 (tablet): uptime 7d, load ~25, MemAvailable ~2.6 GB, 76 third-party apps, storage 26/103 GB. After optimization and reboot MemAvailable ~2.7 GB, 59 packages disabled.

### TV Xiaomi specifics

- Very little RAM (1.8 GB) and storage (4 GB): the main levers are free storage (`pm trim-caches 4G`) and stopping heavy background apps (`am force-stop PACKAGE`, e.g. Crunchyroll). Keep free storage above about 1 GB.
- Only 6 third-party apps (Crunchyroll, Disney+, Spotify, La7, RaiPlay, NPO Start): do not disable them without asking. Never disable Google TV launcher, Play Services/Store, mediatek.* or Xiaomi system packages.
- Thermal sysfs is not readable via adb; skip temperature.
- Baseline 2026-11-26 (just rebooted): MemAvailable ~540 MB, 335 MB swap used, 1.7 GB storage free, 12 packages disabled, animations 0.5x.

## Windows PC (local, PowerShell)

Read-only checks:
- Uptime, RAM, CPU: `Get-CimInstance Win32_OperatingSystem` (LastBootUpTime, FreePhysicalMemory, TotalVisibleMemorySize), `Get-Counter '\Processor(_Total)\% Processor Time'`
- Disk: `Get-PSDrive C`, `Get-PhysicalDisk | Select FriendlyName,HealthStatus`
- Top processes: `Get-Process | Sort WorkingSet -Desc | Select -First 10 Name,@{n='MB';e={[int]($_.WS/1MB)}}`
- Startup apps: `Get-CimInstance Win32_StartupCommand | Select Name,Command`
- Pending updates/reboot and Defender status: `Get-MpComputerStatus | Select AntivirusEnabled,AntivirusSignatureLastUpdated`

Optimize only after the user's OK: clear `$env:TEMP` files older than 7 days, empty nothing else automatically, suggest disabling heavy startup items (list them, do not disable silently), suggest a reboot if uptime is long.

## Report format

For each device: status (ok / attention), 3-5 key numbers, what was changed, what the user must do (reboot, uninstall, enable debugging). Keep it short.
