#!/usr/bin/env python3
"""Validate the skills repo: frontmatter, versions, model lines, agents, cross-references, README matrix.

Usage: python3 scripts/validate.py [--write-readme]
Exit code 1 on any error. Warnings never fail the run.
"""
import glob, json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS = {"opus", "sonnet", "haiku", "main"}
AGENT_MODELS = {"opus", "sonnet", "haiku", "inherit"}
EFFORTS = {"low", "medium", "high", "xhigh", "max"}
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")
# names legitimately referenced that are not directories of this repo
EXTERNAL = {"design", "design-sync", "frontend-design", "taste", "impeccable", "emil-design-eng",
            "animate", "animate-expo", "animation-performance", "review-animations", "break-ui", "mobile-native", "code-review", "laravel-boost",
            "general-purpose", "playwright", "context7", "claude-api"}
errors, warnings = [], []


def err(m): errors.append(m)
def warn(m): warnings.append(m)


def frontmatter(path):
    s = open(path, encoding="utf-8").read()
    m = re.match(r"---\n(.*?)\n---\n", s, re.S)
    if not m:
        err(f"{path}: missing frontmatter"); return {}, s
    try:
        import yaml
        yaml.safe_load(m.group(1))
    except ImportError:
        warn("PyYAML not installed: strict YAML check skipped")
    except Exception as e:
        err(f"{path}: frontmatter is not valid YAML ({str(e).splitlines()[0]}) — quote values containing ': '")
    fm, key = {}, None
    for line in m.group(1).split("\n"):
        if re.match(r"^\s+- ", line) and key:
            fm.setdefault(key, []).append(line.strip()[2:].strip())
        elif ":" in line:
            key, _, v = line.partition(":"); key = key.strip(); v = v.strip()
            if v.startswith('"') and v.endswith('"'):
                import json; v = json.loads(v)
            if v.startswith("[") and v.endswith("]"):
                v = [x.strip() for x in v[1:-1].split(",") if x.strip()]
            fm[key] = v if v else []
    return fm, s[m.end():]


skills, agents = {}, {}
for f in sorted(glob.glob(os.path.join(ROOT, "*", "SKILL.md"))):
    n = os.path.basename(os.path.dirname(f)); rel = os.path.relpath(f, ROOT)
    fm, body = frontmatter(f)
    if fm.get("name") != n: err(f"{rel}: name '{fm.get('name')}' != directory '{n}'")
    if not str(fm.get("description", "")).startswith("Use "): err(f"{rel}: description must start with 'Use ' (a trigger, not a summary)")
    if not SEMVER.match(str(fm.get("version", ""))): err(f"{rel}: version missing or not semver")
    m = re.search(r"^\*\*Run on:\*\* (\w+) · effort (\w+) — .+$", body, re.M)
    if not m: err(f"{rel}: missing '**Run on:** <model> · effort <level> — <reason>' line"); model = effort = "?"
    else:
        model, effort = m.groups()
        if model not in MODELS: err(f"{rel}: Run on model '{model}' not in {sorted(MODELS)}")
        if effort not in EFFORTS: err(f"{rel}: Run on effort '{effort}' invalid")
    fmodel = fm.get("model")
    if model == "opus" and (fmodel != "opus" or fm.get("effort") != effort):
        err(f"{rel}: Run on says opus/{effort} but frontmatter has model={fmodel} effort={fm.get('effort')}")
    if model != "opus" and (fmodel or fm.get("effort")):
        err(f"{rel}: only opus skills may set model/effort in frontmatter (an override lasts the rest of the turn; never force a session down)")
    skills[n] = dict(model=model, effort=effort, version=fm.get("version", "?"), body=body, desc=fm.get("description", ""))

for f in sorted(glob.glob(os.path.join(ROOT, "agents", "*.md"))):
    n = os.path.basename(f)[:-3]; rel = os.path.relpath(f, ROOT)
    fm, body = frontmatter(f)
    if fm.get("name") != n: err(f"{rel}: name '{fm.get('name')}' != file '{n}'")
    if not fm.get("description"): err(f"{rel}: missing description")
    if fm.get("model") not in AGENT_MODELS and not str(fm.get("model", "")).startswith("claude-"): err(f"{rel}: model '{fm.get('model')}' invalid")
    if fm.get("effort") not in EFFORTS: err(f"{rel}: effort missing/invalid")
    if not fm.get("tools"): err(f"{rel}: tools missing (agent would inherit everything)")
    for s in fm.get("skills", []) if isinstance(fm.get("skills"), list) else []:
        if s not in skills: err(f"{rel}: preloads unknown skill '{s}'")
    if "STATUS" not in body: err(f"{rel}: prompt lacks the STATUS report contract")
    if re.search(r"\bgit (commit|push)\b", body) and "Never run git" not in body and "never post" not in body.lower() and "git write" not in body:
        warn(f"{rel}: mentions git commit/push without an explicit prohibition")
    agents[n] = dict(model=fm.get("model"), effort=fm.get("effort"), desc=fm.get("description", ""),
                     skills=fm.get("skills", []), tools=fm.get("tools", ""))

known = set(skills) | set(agents) | EXTERNAL
for n, d in skills.items():
    for line in d["body"].split("\n"):
        if line.startswith("**Pairs with:**"):
            for tok in re.findall(r"`([a-z0-9]+(?:-[a-z0-9]+)*)`", line):
                if tok not in known: err(f"{n}: 'Pairs with' references unknown '{tok}'")

# every skill must be routed to: mentioned by some other skill, the README or CLAUDE.md
corpus = {n: d["body"] for n, d in skills.items()}
claude_md = open(os.path.join(ROOT, "CLAUDE.md"), encoding="utf-8").read() + open(os.path.join(ROOT, "README.md"), encoding="utf-8").read()
for n in skills:
    others = "\n".join(b for k, b in corpus.items() if k != n) + claude_md
    if f"`{n}`" not in others: warn(f"skill '{n}' is not referenced by any other skill or CLAUDE.md (invisible)")

# changelog mentions current version of skills
cl = open(os.path.join(ROOT, "CHANGELOG.md"), encoding="utf-8").read()
for n, d in skills.items():
    if d["version"] != "1.0.0" and f"{n} {d['version']}" not in cl:
        warn(f"CHANGELOG has no '{n} {d['version']}' line")

# README matrix
BEGIN, END = "<!-- matrix:begin -->", "<!-- matrix:end -->"
def matrix():
    out = ["| Skill | Version | Run on | Effort |", "|---|---|---|---|"]
    out += [f"| `{n}` | {d['version']} | {d['model']} | {d['effort']} |" for n, d in sorted(skills.items())]
    out += ["", "| Agent | Model | Effort | Preloaded skills | Role |", "|---|---|---|---|---|"]
    for n, d in sorted(agents.items()):
        role = d["desc"].split(" — ")[0].split(". ")[0][:110]
        out.append(f"| `{n}` | {d['model']} | {d['effort']} | {', '.join(f'`{s}`' for s in d['skills']) or '—'} | {role} |")
    return "\n".join(out)

rp = os.path.join(ROOT, "README.md")
if not os.path.exists(rp): err("README.md missing")
else:
    r = open(rp, encoding="utf-8").read()
    if BEGIN not in r or END not in r: err("README.md lacks matrix markers")
    else:
        new = r[:r.index(BEGIN) + len(BEGIN)] + "\n" + matrix() + "\n" + r[r.index(END):]
        if "--write-readme" in sys.argv:
            open(rp, "w", encoding="utf-8").write(new); print("README matrix written")
        elif new != r: err("README matrix out of date — run: python3 scripts/validate.py --write-readme")

for w in warnings: print("WARN ", w)
for e in errors: print("ERROR", e)
print(f"{len(skills)} skills, {len(agents)} agents, {len(errors)} errors, {len(warnings)} warnings")
sys.exit(1 if errors else 0)
