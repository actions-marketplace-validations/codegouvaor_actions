#!/usr/bin/env bash
#
# government-check.sh — official CodeGouvAOR repository & government validation.
#
# Deterministic, dependency-free (git, find, grep only) checks against a checked
# out repository. Every check is documented in the action README; the strictness
# of each category is controlled by inputs. Failures make the step fail;
# warnings are reported in the job summary without failing (unless
# `fail-on-warning` is enabled).

set -euo pipefail

WORKING_DIRECTORY="${WORKING_DIRECTORY:-.}"
README_REQUIRED="${README_REQUIRED:-true}"
LICENSE_REQUIRED="${LICENSE_REQUIRED:-true}"
GITIGNORE_REQUIRED="${GITIGNORE_REQUIRED:-false}"
CODEOWNERS_REQUIRED="${CODEOWNERS_REQUIRED:-false}"
PUBLICCODE_REQUIRED="${PUBLICCODE_REQUIRED:-false}"
DEPENDABOT_REQUIRED="${DEPENDABOT_REQUIRED:-false}"
SECRET_SCAN="${SECRET_SCAN:-true}"
FAIL_ON_SECRET="${FAIL_ON_SECRET:-true}"
FAIL_ON_WARNING="${FAIL_ON_WARNING:-false}"
MAX_FILE_SIZE_MB="${MAX_FILE_SIZE_MB:-10}"
EXCLUDE="${EXCLUDE:-}"

OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/null}"
SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/dev/null}"

errors=0
warnings=0
passed=0

emit() { printf '%s=%s\n' "$1" "$2" >>"$OUTPUT_FILE"; }
summary() { printf '%s\n' "$1" >>"$SUMMARY_FILE"; }

fail() {
    echo "::error::$1"
    errors=$((errors + 1))
    summary "- [FAIL] $1"
}
warn() {
    echo "::warning::$1"
    warnings=$((warnings + 1))
    summary "- [WARN] $1"
}
ok() {
    summary "- [OK] $1"
    passed=$((passed + 1))
}

# require_file <label> <present(bool)> <required(bool)>
require_file() {
    local label="$1" present="$2" required="$3"
    if [ "$present" = "true" ]; then
        ok "$label present"
    elif [ "$required" = "true" ]; then
        fail "missing $label"
    else
        warn "missing $label"
    fi
}

cd "$WORKING_DIRECTORY"

summary "### CodeGouvAOR Government Check"
summary ""

# ---------------------------------------------------------------------------
# README / LICENSE / .gitignore
# ---------------------------------------------------------------------------
has_readme=false
for candidate in README.md README.rst README.txt README readme.md Readme.md; do
    if [ -f "$candidate" ]; then
        has_readme=true
        break
    fi
done

has_license=false
for candidate in LICENSE LICENSE.md LICENSE.txt LICENSE-MIT COPYING COPYING.md; do
    if [ -f "$candidate" ]; then
        has_license=true
        break
    fi
done

has_gitignore=false
[ -f .gitignore ] && has_gitignore=true

require_file "README" "$has_readme" "$README_REQUIRED"
require_file "LICENSE" "$has_license" "$LICENSE_REQUIRED"
require_file ".gitignore" "$has_gitignore" "$GITIGNORE_REQUIRED"

# ---------------------------------------------------------------------------
# GitHub / CodeGouvAOR conventions
# ---------------------------------------------------------------------------
has_codeowners=false
for candidate in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do
    [ -f "$candidate" ] && has_codeowners=true
done
require_file "CODEOWNERS" "$has_codeowners" "$CODEOWNERS_REQUIRED"

has_publiccode=false
[ -f publiccode.yml ] && has_publiccode=true
require_file "publiccode.yml" "$has_publiccode" "$PUBLICCODE_REQUIRED"

has_dependabot=false
[ -f .github/dependabot.yml ] && has_dependabot=true
require_file ".github/dependabot.yml" "$has_dependabot" "$DEPENDABOT_REQUIRED"

# Minimal metadata, when the corresponding manifests exist.
if [ -f package.json ]; then
    if grep -q '"name"' package.json; then
        ok "package.json name declared"
    else
        warn "package.json has no 'name'"
    fi
    if grep -q '"version"' package.json; then
        ok "package.json version declared"
    else
        warn "package.json has no 'version'"
    fi
fi

if [ -f go.mod ]; then
    if grep -q '^module ' go.mod; then
        ok "go.mod declares a module"
    else
        warn "go.mod has no 'module' directive"
    fi
fi

# ---------------------------------------------------------------------------
# Problematic files (warnings)
# ---------------------------------------------------------------------------
in_git=false
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    in_git=true
fi

max_bytes=$((MAX_FILE_SIZE_MB * 1024 * 1024))

# Tracked `.env` (excluding examples/samples/templates) is a credential risk.
if [ "$in_git" = "true" ]; then
    tracked_env="$(git ls-files | grep -E '(^|/)\.env$' || true)"
    if [ -n "$tracked_env" ]; then
        warn "tracked .env file(s): ${tracked_env//$'\n'/, }"
    else
        ok "no tracked .env file"
    fi
fi

# Populate the file list: tracked files in git, otherwise a plain walk.
files=()
if [ "$in_git" = "true" ]; then
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(git ls-files -z)
else
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find . -type f -not -path './.git/*' -print0)
fi

large_reported=0
for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    size="$(wc -c <"$f" 2>/dev/null || echo 0)"
    if [ "$size" -gt "$max_bytes" ]; then
        if [ "$large_reported" -lt 5 ]; then
            warn "large tracked file (>${MAX_FILE_SIZE_MB}MB): $f"
        fi
        large_reported=$((large_reported + 1))
    fi
done
if [ "$large_reported" -eq 0 ]; then
    ok "no large tracked files"
else
    summary "- [INFO] $large_reported large file(s) total"
fi

# ---------------------------------------------------------------------------
# Secret scan (high-confidence patterns only)
# ---------------------------------------------------------------------------
secrets_found=false
secret_report=""

patterns=(
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    'AKIA[0-9A-Z]{16}'
    'ASIA[0-9A-Z]{16}'
    'ghp_[0-9A-Za-z]{36}'
    'gho_[0-9A-Za-z]{36}'
    'ghs_[0-9A-Za-z]{36}'
    'ghr_[0-9A-Za-z]{36}'
    'github_pat_[0-9A-Za-z_]{22,}'
    'xox[baprs]-[0-9A-Za-z-]{10,}'
    'AIza[0-9A-Za-z_-]{35}'
    'sk_live_[0-9A-Za-z]{24,}'
    'npm_[0-9A-Za-z]{36}'
)

if [ "$SECRET_SCAN" = "true" ]; then
    grep_args=()
    for pattern in "${patterns[@]}"; do
        grep_args+=(-e "$pattern")
    done

    for f in "${files[@]}"; do
        [ -f "$f" ] || continue
        case "$f" in
            .git/* | *.lock | pnpm-lock.yaml | package-lock.json | yarn.lock | go.sum)
                continue
                ;;
            *.min.js | *.map | vendor/* | node_modules/* | test/fixtures/* | tests/fixtures/*)
                continue
                ;;
        esac
        if [ -n "$EXCLUDE" ]; then
            skip=false
            while IFS= read -r excluded; do
                [ -z "$excluded" ] && continue
                # shellcheck disable=SC2254
                case "$f" in
                    $excluded) skip=true ;;
                esac
            done <<<"$EXCLUDE"
            [ "$skip" = "true" ] && continue
        fi
        size="$(wc -c <"$f" 2>/dev/null || echo 0)"
        if [ "$size" -gt "$max_bytes" ]; then
            continue
        fi
        if matches="$(grep -nEI "${grep_args[@]}" -- "$f" 2>/dev/null)"; then
            secrets_found=true
            secret_report="${secret_report}${matches}"$'\n'
        fi
    done
fi

if [ "$secrets_found" = "true" ]; then
    summary ""
    summary "### Potential secrets"
    summary ""
    summary '```'
    summary "${secret_report%$'\n'}"
    summary '```'
    if [ "$FAIL_ON_SECRET" = "true" ]; then
        fail "potential secret(s) detected in tracked files"
    else
        warn "potential secret(s) detected in tracked files"
    fi
else
    ok "secret scan found no matches"
fi

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
emit has-readme "$has_readme"
emit has-license "$has_license"
emit has-gitignore "$has_gitignore"
emit has-codeowners "$has_codeowners"
emit has-publiccode "$has_publiccode"
emit secrets-found "$secrets_found"
emit errors "$errors"
emit warnings "$warnings"
emit checks-passed "$passed"

if [ "$errors" -gt 0 ]; then
    emit status "fail"
    summary ""
    summary "Government check failed: $errors error(s), $warnings warning(s)."
    exit 1
fi

if [ "$FAIL_ON_WARNING" = "true" ] && [ "$warnings" -gt 0 ]; then
    emit status "fail"
    summary ""
    summary "Government check failed on warnings (fail-on-warning): $warnings warning(s)."
    exit 1
fi

emit status "pass"
summary ""
summary "Government check passed: $passed check(s), $warnings warning(s)."