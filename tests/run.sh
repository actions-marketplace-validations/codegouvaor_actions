#!/usr/bin/env bash
#
# Unit tests for the composite action scripts.
#
# These tests run the shell scripts directly (the same ones the composite
# actions execute) against the fixtures under tests/fixtures. They do not
# require network access.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$REPO_ROOT/actions"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

pass=0
fail=0

fail_test() {
    echo "FAIL: $1"
    fail=$((fail + 1))
}

pass_test() {
    pass=$((pass + 1))
}

# run_script <script> [env assignments...]  -- runs a script with GITHUB_OUTPUT
# and GITHUB_STEP_SUMMARY pointed at temp files, in a throwaway work dir.
run_script() {
    local script="$1"
    shift
    export GITHUB_OUTPUT="$tmpdir/out"
    export GITHUB_STEP_SUMMARY="$tmpdir/summary"
    : >"$GITHUB_OUTPUT"
    : >"$GITHUB_STEP_SUMMARY"
    # shellcheck disable=SC2016
    env "$@" bash "$script" >/dev/null
}

# get_output <key>
get_output() {
    grep "^$1=" "$tmpdir/out" | tail -n1 | cut -d= -f2- || true
}

echo "== detect.sh =="

run_script "$SCRIPT_DIR/government-check/scripts/detect.sh" WORKING_DIRECTORY="$REPO_ROOT/tests/fixtures/node-app"
if [ "$(get_output is-node)" = "true" ] && [ "$(get_output package-manager)" = "npm" ]; then
    pass_test "node detection (npm)"
else
    fail_test "node detection (npm): is-node=$(get_output is-node) pm=$(get_output package-manager)"
fi

run_script "$SCRIPT_DIR/government-check/scripts/detect.sh" WORKING_DIRECTORY="$REPO_ROOT/tests/fixtures/go-app"
if [ "$(get_output is-go)" = "true" ] && [ "$(get_output project-type)" = "go" ]; then
    pass_test "go detection"
else
    fail_test "go detection: is-go=$(get_output is-go)"
fi

run_script "$SCRIPT_DIR/government-check/scripts/detect.sh" WORKING_DIRECTORY="$REPO_ROOT/tests/fixtures/docker-app"
if [ "$(get_output is-docker)" = "true" ]; then
    pass_test "docker detection"
else
    fail_test "docker detection"
fi

run_script "$SCRIPT_DIR/government-check/scripts/detect.sh" WORKING_DIRECTORY="$REPO_ROOT/tests/fixtures/mixed"
if [ "$(get_output is-node)" = "true" ] \
    && [ "$(get_output is-go)" = "true" ] \
    && [ "$(get_output is-docker)" = "true" ] \
    && [ "$(get_output project-type)" = "mixed" ]; then
    pass_test "mixed detection"
else
    fail_test "mixed detection: project-type=$(get_output project-type)"
fi

run_script "$SCRIPT_DIR/government-check/scripts/detect.sh" WORKING_DIRECTORY="$REPO_ROOT/tests/fixtures/go-app" PROJECT_TYPE=node
if [ "$(get_output is-node)" = "true" ] && [ "$(get_output is-go)" = "false" ]; then
    pass_test "forced project-type=node"
else
    fail_test "forced project-type=node"
fi

run_script "$SCRIPT_DIR/government-check/scripts/detect.sh" WORKING_DIRECTORY="$REPO_ROOT/tests/fixtures/mixed" PROJECT_TYPE=none
if [ "$(get_output is-node)" = "false" ] && [ "$(get_output project-type)" = "none" ]; then
    pass_test "forced project-type=none"
else
    fail_test "forced project-type=none"
fi

echo "== repository-check.sh =="

okdir="$tmpdir/ok"
mkdir -p "$okdir"
printf '# ok\n' >"$okdir/README.md"
printf 'MIT\n' >"$okdir/LICENSE"
printf 'node_modules/\n' >"$okdir/.gitignore"
run_script "$SCRIPT_DIR/repository-check/scripts/repository-check.sh" WORKING_DIRECTORY="$okdir" SECRET_SCAN=false
if [ "$(get_output result)" = "pass" ] && [ "$(get_output has-readme)" = "true" ] && [ "$(get_output has-license)" = "true" ]; then
    pass_test "well-formed repository passes"
else
    fail_test "well-formed repository passes: result=$(get_output result)"
fi

baddir="$tmpdir/bad"
mkdir -p "$baddir"
run_script "$SCRIPT_DIR/repository-check/scripts/repository-check.sh" WORKING_DIRECTORY="$baddir" SECRET_SCAN=false || true
if [ "$(get_output result)" = "fail" ]; then
    pass_test "missing README/LICENSE fails"
else
    fail_test "missing README/LICENSE fails: result=$(get_output result)"
fi

# Secret scan over a throwaway git repo with a planted credential.
# The token is assembled at runtime so this test file itself stays clean.
secretdir="$tmpdir/leak"
mkdir -p "$secretdir"
printf '# ok\n' >"$secretdir/README.md"
token_prefix="github_pat"
token_body="0123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij"
printf '%s_%s\n' "$token_prefix" "$token_body" >"$secretdir/creds.txt"
(
    cd "$secretdir"
    git init -q
    git add README.md creds.txt
    git -c user.email=t@t -c user.name=t commit -qm init
)
run_script "$SCRIPT_DIR/repository-check/scripts/repository-check.sh" WORKING_DIRECTORY="$secretdir" README_REQUIRED=false LICENSE_REQUIRED=false || true
if [ "$(get_output secrets-found)" = "true" ]; then
    pass_test "secret scan detects planted credential"
else
    fail_test "secret scan detects planted credential: secrets-found=$(get_output secrets-found)"
fi

echo "== ads-check.sh =="

adsdir="$tmpdir/ads"
mkdir -p "$adsdir"
printf '{\n  "dependencies": { "@codegouvaor/react-ads": "^0.1.0" }\n}\n' >"$adsdir/package.json"
run_script "$SCRIPT_DIR/ads-check/scripts/ads-check.sh" WORKING_DIRECTORY="$adsdir"
if [ "$(get_output used)" = "true" ] && [ "$(get_output version)" = "0.1.0" ]; then
    pass_test "ads dependency detected"
else
    fail_test "ads dependency detected: used=$(get_output used) version=$(get_output version)"
fi

nodeps="$tmpdir/noads"
mkdir -p "$nodeps"
printf '{ "name": "x", "version": "1.0.0" }\n' >"$nodeps/package.json"
run_script "$SCRIPT_DIR/ads-check/scripts/ads-check.sh" WORKING_DIRECTORY="$nodeps"
if [ "$(get_output used)" = "false" ] && [ "$(get_output result)" = "pass" ]; then
    pass_test "ads check passes when not used"
else
    fail_test "ads check passes when not used: used=$(get_output used)"
fi

echo ""
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]