---
name: device-health
description: Use when the user asks to check, diagnose, speed up, clean or optimize their own devices - Samsung phone SM-S911B, Samsung tablet SM-X230 and Xiaomi TV over adb, or the Windows PC - or says one of them is slow.
version: 1.1.0
---

# Device health check and optimization

**Run on:** main · effort low — read-only diagnostics plus reversible settings, run in the current session.

**Pairs with:** `handling-sudo-and-missing-tools` (ask before installing a missing tool such as adb), `direct-execution` (this is linear work, no subagents).

Devices: phone (Galaxy S23, SM-S911B, Android 17, 7 GB RAM), tablet (Samsung SM-X230, Android 16, 5.7 GB RAM), TV (Xiaomi MiTV-MZTU0, Android 14 / Google TV, 1.8 GB RAM, 4 GB storage), Windows 11 PC.
Another session may already be working on the TV: if the user says so, do not touch it.
Reply to the user in Italian. Run diagnostics first, report, then optimize. Ask before anything not reversible.

## First: where is this session running?

- `uname -a` says `PRoot` (Claude Code in Termux on the phone): use **Phone host** below. The PC is not reachable over adb; its section applies only to a session on the PC.
- Windows: use **PC host** below.

## adb (phone, tablet and TV)

Wireless debugging must be on (Settings -> Developer options), same Wi-Fi. Pairing is stored per host: a device paired from the PC is not paired from the phone, and the reverse. All three devices were paired from the phone on 2026-11-26, so on that host do **not** ask for a code first; try to connect, and ask for pairing only if that fails.

- Pair: `adb pair IP:PAIRPORT CODE`. Code and pairing port come from the "pair with code" screen and expire when it closes, so run the command at once. `protocol fault (couldn't read status message)` was seen with the pairing port already closed: ask for a fresh code.
- The connect port differs from the pairing port and changes after a reboot or a toggle. Reboot can also switch Wireless debugging off: no open port means ask the user to turn it on.
- Always target with `-s IP:PORT`. A stale `offline` entry: `adb disconnect IP:PORT`, reconnect.
- IPs seen (DHCP, may change): phone 192.168.1.135, tablet 192.168.1.21, TV 192.168.1.95.
- Do not run `adb tcpip 5555`: the Claude Code auto mode classifier denied it, it leaves a fixed port open, and the paired connection works without it.
- Check `adb devices -l` first. Another device may already be connected.
- When done, remind the user to turn Wireless debugging off.

### Phone host (Termux + PRoot)

- adb is `/usr/bin/adb`. The shell sees nothing of Android (no app list, battery, shared storage) until adb is connected, including for the phone it runs on, which connects to its own Wi-Fi IP. `uptime` and `ip` of the PRoot shell are not device diagnostics.
- `adb mdns services` returned nothing here. Find the connect port by trying the open ports of that one known device:

```bash
H=192.168.1.21   # one of the user's own devices, listed above
for p in $(python3 -I - "$H" <<'EOF'
import socket, sys
for p in range(30000, 50001):
    s = socket.socket(); s.settimeout(0.3)
    if s.connect_ex((sys.argv[1], p)) == 0 and s.getsockname() != s.getpeername(): print(p)
    s.close()
EOF
); do r=$(timeout 10 adb connect $H:$p 2>&1); echo "$p $r"; case "$r" in *"connected to"*) break;; esac; adb disconnect $H:$p >/dev/null 2>&1; done
```

- Rebooting the phone ends the Claude session: say so before suggesting it (`claude --continue` resumes).
- For the phone's own pairing the code screen must stay open while the user types to the terminal (split screen); on this phone it can close on focus loss.

### PC host (Windows)

- adb: `C:\platform-tools\adb.exe`. If missing, download https://dl.google.com/android/repository/platform-tools-latest-windows.zip, extract into a new empty scratch folder, then move `platform-tools` to `C:\`.
- Find the connect port with `adb mdns services` (entry `_adb-tls-connect._tcp`).
- The TV was reached on `192.168.1.95:5555` from the PC; on 2026-11-26 that port refused connections from the phone.
- Run each adb command as its own call or script; PowerShell breaks on `sed`/`grep` quoting inside `adb shell`, so filter output with `Select-String`.

### Diagnose (read-only)

```
adb -s D shell "getprop ro.product.model; getprop ro.build.version.release"
adb -s D shell "grep -E 'MemTotal|MemAvailable|SwapFree' /proc/meminfo"
adb -s D shell "df -h /data | tail -1"
adb -s D shell uptime                       # long uptime = suggest reboot; judge load with top
adb -s D shell "top -b -n 1 | head -5"      # tasks, CPU
adb -s D shell "dumpsys meminfo"            # 'Total PSS by process' = top RAM users
adb -s D shell "dumpsys battery"            # level, temperature (tenths of C)
adb -s D shell "pm list packages -3"        # third-party apps
adb -s D shell "pm list packages -d"        # disabled apps
```

Last-used date per app: parse `dumpsys usagestats` lines `package=X totalTimeUsed="..." lastTimeUsed="..."`, keep the max lastTimeUsed per package. 1970-01-01 means never used.

### Optimize (safe, reversible)

1. `pm trim-caches 100G` on phone and tablet, `4G` on the TV (asks for that much free space, so a large value clears all caches).
2. Animations 0.5x: `settings put global window_animation_scale 0.5` (also `transition_animation_scale`, `animator_duration_scale`).
3. `cmd package bg-dexopt-job` (can take over 3 minutes: run in background).
4. `am kill-all` (not on the phone host's own phone: it may hit the terminal).
5. Unused apps: propose a list (not used for 3+ months or never used, no system or essential apps) and get the user's OK, then `pm disable-user --user 0 PACKAGE`. Undo with `pm enable PACKAGE`. Never disable Samsung/Google core, launcher, keyboard, Play Store/Services, banking/DigiD/authenticator apps.
6. Tell the user to reboot if uptime is more than a few days. Wireless debugging drops after reboot, so ask them to re-enable it before re-checking.

Known quirk: apps with `enabled=4` in `dumpsys package` are already dormant (disabled until used); `pm disable-user` fails on them with "Shell cannot change component state for null". They use no RAM; skip them.

`dumpsys diskstats` gives per-app sizes (App + Data + Cache) but is a cached snapshot: do not read it as proof that a cleanup did or did not happen. On the tablet a load average around 25 with CPU over 90% idle is normal, also right after a reboot.

Baseline from 2026-11-26 (tablet): uptime 7d, load ~25, MemAvailable ~2.6 GB, 76 third-party apps, storage 26/103 GB. After optimization and reboot MemAvailable ~2.7 GB, 59 packages disabled. Later the same day a cache trim took used storage from 26 to 22 GB.

Baseline 2026-11-26 (phone): before, 11 GB free of 104 and MemAvailable 1.7 GB; after cache trim and reboot, 16 GB free and 2.8 GB. Largest: photos/videos 14 GB, Spotify 10.9 GB, app media 10 GB. Keep banking, identity and government apps even when unused.

### TV Xiaomi specifics

- Very little RAM (1.8 GB) and storage (4 GB): the main levers are free storage (`pm trim-caches 4G`) and stopping heavy background apps (`am force-stop PACKAGE`, e.g. Crunchyroll). Keep free storage above about 1 GB.
- Only 6 third-party apps (Crunchyroll, Disney+, Spotify, La7, RaiPlay, NPO Start): do not disable them without asking. Never disable Google TV launcher, Play Services/Store, mediatek.* or Xiaomi system packages.
- Thermal sysfs is not readable via adb; skip temperature.
- Baseline 2026-11-26 (just rebooted): MemAvailable ~540 MB, 335 MB swap used, 1.7 GB storage free, 12 packages disabled, animations 0.5x.

## Windows PC (PC host, PowerShell)

Read-only checks:
- Uptime, RAM, CPU: `Get-CimInstance Win32_OperatingSystem` (LastBootUpTime, FreePhysicalMemory, TotalVisibleMemorySize), `Get-Counter '\Processor(_Total)\% Processor Time'`
- Disk: `Get-PSDrive C`, `Get-PhysicalDisk | Select FriendlyName,HealthStatus`
- Top processes: `Get-Process | Sort WorkingSet -Desc | Select -First 10 Name,@{n='MB';e={[int]($_.WS/1MB)}}`
- Startup apps: `Get-CimInstance Win32_StartupCommand | Select Name,Command`
- Pending updates/reboot and Defender status: `Get-MpComputerStatus | Select AntivirusEnabled,AntivirusSignatureLastUpdated`

Optimize only after the user's OK: clear `$env:TEMP` files older than 7 days, empty nothing else automatically, suggest disabling heavy startup items (list them, do not disable silently), suggest a reboot if uptime is long.

## Report format

For each device: status (ok / attention), 3-5 key numbers, what was changed, what the user must do (reboot, uninstall, enable debugging). Keep it short.
