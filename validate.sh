#!/usr/bin/env bash
set -e

ERRORS=0

echo "=== dotfiles validation ==="
echo ""

# Check 1: templates are valid JSON (placeholder replaced for parsing)
echo "Check 1: template JSON syntax"
for template in templates/*.json; do
  sed "s|<repo-path>|/tmp/test|g" "$template" | python3 -m json.tool > /dev/null \
    && echo "  OK: $template" \
    || { echo "  FAIL: $template"; ERRORS=$((ERRORS+1)); }
done

# Check 2: no hardcoded absolute paths in templates
echo "Check 2: no hardcoded paths in templates"
if grep -rn "/home/" templates/ 2>/dev/null; then
  echo "  FAIL: hardcoded path found above"
  ERRORS=$((ERRORS+1))
else
  echo "  OK: no hardcoded paths"
fi

# Check 3: scripts are executable
echo "Check 3: scripts are executable"
for script in install.sh bootstrap.sh validate.sh; do
  if [ -x "$script" ]; then
    echo "  OK: $script"
  else
    echo "  FAIL: $script is not executable (run: chmod +x $script)"
    ERRORS=$((ERRORS+1))
  fi
done

# Check 4: gitconfig template exists
echo "Check 4: gitconfig template exists"
if [ -f templates/gitconfig ]; then
  echo "  OK: templates/gitconfig"
else
  echo "  FAIL: templates/gitconfig missing"
  ERRORS=$((ERRORS+1))
fi

# Check 5: no module backs up a secret (the repo is public). The lists decide what is
# copied in, so a secret named in one would reach GitHub with the next sync.
echo "Check 5: no secrets in the workstation backup lists"
forbidden='credentials|sunshine_state\.json|portal_token|sunshine-session-watch/|\.cred$|\.env$|/\.ssh/|\.gnupg/|(^|/)\.?secrets?(/|$)|_token|token$|password|api[_-]?key'
if grep -vh '^#' scripts/workstation/*/*.list | grep -inE "$forbidden"; then
  echo "  FAIL: a secret is listed above - remove it from the list and the file from the repo"
  ERRORS=$((ERRORS+1))
else
  echo "  OK: no secrets listed"
fi
for secret in credentials sunshine_state.json portal_token api.cred; do
  if [ -e "scripts/workstation/sunshine/config/$secret" ]; then
    echo "  FAIL: scripts/workstation/sunshine/config/$secret exists"
    ERRORS=$((ERRORS+1))
  fi
done

# Check 6: every workstation module keeps the contract restore-all.sh and sync-all.sh
# rely on: an executable restore.sh and sync-from-live.sh (README, "Workstation modules")
echo "Check 6: workstation modules have restore.sh and sync-from-live.sh"
for dir in scripts/workstation/*/; do
  for script in restore.sh sync-from-live.sh; do
    if [ -x "$dir$script" ]; then
      echo "  OK: $dir$script"
    else
      echo "  FAIL: $dir$script missing or not executable"
      ERRORS=$((ERRORS+1))
    fi
  done
done

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "PASS: all checks passed."
else
  echo "FAIL: $ERRORS error(s) found."
  exit 1
fi
