#!/usr/bin/env python3
"""Validate composite action manifests in this repository.

Checks every `actions/*/action.yml` plus the root `action.yml` (the official
Marketplace action). For each manifest it verifies:
  - the file is valid YAML (full mode when PyYAML is installed, which CI does);
  - it declares a `name`;
  - it is a composite action (`runs.using: composite`);
  - `$/actions/<name>` references resolve to an existing action;
  - Marketplace requirements: a short description (<= 125 chars), `author` and
    `branding` are present.

The script-reference check is text-based and therefore always runs, even when
PyYAML is not installed locally.
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

SCRIPT_REF = re.compile(r"scripts/([A-Za-z0-9_.-]+)")
SELF_REF = re.compile(r"\$/actions/([A-Za-z0-9_.-]+)")
# GitHub-supported branding colors.
VALID_COLORS = {"white", "yellow", "blue", "green", "orange", "red", "purple", "gray"}
# GitHub-supported branding icons (octicons). Actions may use any of these.
VALID_ICONS = {
    "activity", "airplay", "alert-circle", "alert-octagon", "alert-triangle",
    "align-center", "align-justify", "align-left", "align-right", "anchor",
    "aperture", "archive", "arrow-down", "arrow-down-circle", "arrow-down-left",
    "arrow-down-right", "arrow-left", "arrow-left-circle", "arrow-right",
    "arrow-right-circle", "arrow-up", "arrow-up-circle", "arrow-up-left",
    "arrow-up-right", "at-sign", "award", "bar-chart", "bar-chart-2", "battery",
    "battery-charging", "bell", "bell-off", "bluetooth", "bold", "book", "book-open",
    "bookmark", "box", "briefcase", "calendar", "camera", "camera-off", "cast",
    "check", "check-circle", "check-square", "chevron-down", "chevron-left",
    "chevron-right", "chevron-up", "chevrons-down", "chevrons-left",
    "chevrons-right", "circle", "clipboard", "clock", "cloud", "cloud-drizzle",
    "cloud-lightning", "cloud-off", "cloud-rain", "cloud-snow", "code",
    "codepen", "codesandbox", "coffee", "columns", "command", "compass", "copy",
    "corner-down-left", "corner-down-right", "corner-left-down", "corner-left-up",
    "corner-right-down", "corner-right-up", "corner-up-left", "corner-up-right",
    "cpu", "credit-card", "crop", "crosshair", "database", "delete", "disc",
    "divide", "divide-circle", "divide-square", "dollar-sign", "download",
    "download-cloud", "dribbble", "droplet", "droplet-off", "edit", "edit-2",
    "edit-3", "external-link", "eye", "eye-off", "facebook", "fast-forward",
    "feather", "figma", "file", "file-minus", "file-plus", "file-text", "film",
    "filter", "flag", "folder", "folder-minus", "folder-plus", "framer",
    "frown", "gift", "git-branch", "git-commit", "git-merge", "git-pull-request",
    "github", "gitlab", "globe", "grid", "hard-drive", "hash", "headphones",
    "heart", "help-circle", "hexagon", "home", "image", "inbox", "info", "instagram",
    "italic", "key", "layers", "layout", "life-buoy", "link", "link-2", "linkedin",
    "list", "loader", "lock", "log-in", "log-out", "mail", "map", "map-pin",
    "maximize", "maximize-2", "meh", "menu", "message-circle", "message-square",
    "mic", "mic-off", "minimize", "minimize-2", "minus", "minus-circle",
    "minus-square", "monitor", "moon", "more-horizontal", "more-vertical", "mouse-pointer",
    "move", "music", "navigation", "navigation-2", "octagon", "package",
    "paperclip", "pause", "pause-circle", "pen-tool", "percent", "phone", "phone-call",
    "phone-forwarded", "phone-incoming", "phone-missed", "phone-off", "phone-outgoing",
    "pie-chart", "play", "play-circle", "plus", "plus-circle", "plus-square",
    "pocket", "power", "printer", "radio", "refresh-ccw", "refresh-cw", "repeat",
    "rewind", "rotate-ccw", "rotate-cw", "rss", "save", "scissors", "search",
    "send", "server", "settings", "share", "share-2", "shield", "shield-off",
    "shopping-bag", "shopping-cart", "shuffle", "sidebar", "skip-back", "skip-forward",
    "slack", "slash", "sliders", "smartphone", "smile", "speaker", "square",
    "star", "stop-circle", "sun", "sunrise", "sunset", "tablet", "tag", "target",
    "terminal", "thermometer", "thumbs-down", "thumbs-up", "toggle-left",
    "toggle-right", "tool", "trash", "trash-2", "trello", "trending-down",
    "trending-up", "triangle", "truck", "tv", "twitch", "twitter", "type",
    "umbrella", "underline", "unlock", "upload", "upload-cloud", "user", "user-check",
    "user-minus", "user-plus", "user-x", "users", "video", "video-off", "voicemail",
    "volume", "volume-1", "volume-2", "volume-x", "watch", "wifi", "wifi-off",
    "wind", "x", "x-circle", "x-octagon", "x-square", "youtube", "zap", "zap-off",
    "zoom-in", "zoom-out",
}

failures = 0


def check_scripts(manifest, text):
    ok = True
    for match in SCRIPT_REF.finditer(text):
        candidate = manifest.parent / "scripts" / match.group(1)
        if not candidate.exists():
            print(f"FAIL {manifest}: referenced script not found: {candidate}")
            ok = False
    return ok


def check_self_refs(manifest, text):
    global failures
    ok = True
    for match in SELF_REF.finditer(text):
        target = ACTIONS / match.group(1) / "action.yml"
        if not target.exists():
            print(f"FAIL {manifest}: $/actions/{match.group(1)} does not exist")
            ok = False
    return ok


def check_marketplace(manifest, data):
    """Marketplace-facing requirements for the action being published."""
    issues = 0
    if not isinstance(data, dict):
        return issues
    description = data.get("description")
    if isinstance(description, str) and len(description) > 125:
        print(f"FAIL {manifest}: description is {len(description)} chars (Marketplace limit is 125)")
        issues += 1
    if not data.get("author"):
        print(f"FAIL {manifest}: missing 'author'")
        issues += 1
    branding = data.get("branding")
    if not isinstance(branding, dict):
        print(f"FAIL {manifest}: missing 'branding'")
        issues += 1
    else:
        if branding.get("color") not in VALID_COLORS:
            print(f"FAIL {manifest}: unsupported branding color: {branding.get('color')!r}")
            issues += 1
        if branding.get("icon") not in VALID_ICONS:
            print(f"FAIL {manifest}: unsupported branding icon: {branding.get('icon')!r}")
            issues += 1
    return issues


def manifests():
    """Return all action metadata files to validate, root action first."""
    root = ROOT / "action.yml"
    out = []
    if root.exists():
        out.append(root)
    out.extend(sorted(ACTIONS.glob("*/action.yml")))
    return out


for manifest in manifests():
    text = manifest.read_text()
    ok = check_scripts(manifest, text)
    ok = check_self_refs(manifest, text) and ok

    if HAVE_YAML:
        try:
            data = yaml.safe_load(text)
        except yaml.YAMLError as exc:  # pragma: no cover - defensive
            print(f"FAIL invalid YAML: {manifest}: {exc}")
            failures += 1
            continue

        if not isinstance(data, dict) or not data.get("name"):
            print(f"FAIL {manifest}: missing 'name'")
            ok = False
        runs = data.get("runs") if isinstance(data, dict) else None
        if not isinstance(runs, dict) or runs.get("using") != "composite":
            print(f"FAIL {manifest}: expected a composite action (runs.using: composite)")
            ok = False
        issues = check_marketplace(manifest, data)
        if issues:
            ok = False
        mode = "full"
    else:  # pragma: no cover - depends on environment
        if not re.search(r"^\s*using:\s*composite\s*$", text, re.M):
            print(f"FAIL {manifest}: expected 'using: composite'")
            ok = False
        mode = "minimal"

    if ok:
        print(f"OK {manifest.relative_to(ROOT)} ({mode})")
    else:
        failures += 1

if not HAVE_YAML:  # pragma: no cover - depends on environment
    print("Note: PyYAML not installed; ran minimal structural validation only.")

if failures:
    print(f"{failures} action error(s).")
    sys.exit(1)
print("All actions valid.")