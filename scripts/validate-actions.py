#!/usr/bin/env python3
"""Validate composite action manifests in this repository.

Checks that every `actions/*/action.yml` is valid YAML, is a composite action,
and that the script referenced in its `runs.steps` actually exists.

PyYAML is used when available (installed in CI). When it is not installed, a
minimal text-based validation is performed instead so the script still works
locally without extra dependencies.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ACTIONS = ROOT / "actions"

try:
    import yaml

    HAVE_YAML = True
except ImportError:  # pragma: no cover - depends on environment
    HAVE_YAML = False

failures = 0


def validate(manifest, data, mode):
    name = data.get("name") if isinstance(data, dict) else None
    if not name:
        print(f"FAIL {manifest}: missing 'name'")
        return False

    runs = data.get("runs") if isinstance(data, dict) else {}
    if not isinstance(runs, dict) or runs.get("using") != "composite":
        print(f"FAIL {manifest}: expected a composite action (runs.using: composite)")
        return False

    ok = True
    for step in runs.get("steps", []) or []:
        run = step.get("run") if isinstance(step, dict) else None
        if run and run.startswith("bash "):
            token = run.split(" ", 1)[1].split(" ")[0]
            script_name = pathlib.Path(token).name
            candidate = manifest.parent / "scripts" / script_name
            if not candidate.exists():
                print(f"FAIL {manifest}: referenced script not found: {candidate}")
                ok = False
    print(f"OK {manifest.relative_to(ROOT)} ({mode}): {name}")
    return ok


for manifest in sorted((ACTIONS / "*" / "action.yml").glob("*.yml")):
    text = manifest.read_text()
    if HAVE_YAML:
        try:
            data = yaml.safe_load(text)
        except yaml.YAMLError as exc:  # pragma: no cover - defensive
            print(f"FAIL invalid YAML: {manifest}: {exc}")
            failures += 1
            continue
        if not validate(manifest, data, "full"):
            failures += 1
    else:  # pragma: no cover - depends on environment
        # Minimal structural check without PyYAML.
        data = {"name": "?", "runs": {}}
        if re.search(r"^\s*using:\s*composite\s*$", text, re.M):
            data["runs"] = {"using": "composite", "steps": []}
        if not validate(manifest, data, "minimal"):
            failures += 1

if not HAVE_YAML:  # pragma: no cover - depends on environment
    print("Note: PyYAML not installed; ran minimal validation only.")

if failures:
    print(f"{failures} composite action error(s).")
    sys.exit(1)
print("All composite actions valid.")