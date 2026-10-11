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

# Check 5: the Sunshine backup lists none of Sunshine's secrets (the repo is public)
echo "Check 5: no Sunshine secrets in the backup lists"
forbidden='credentials|sunshine_state\.json|portal_token|sunshine-session-watch/|\.cred$'
if grep -vh '^#' scripts/workstation/sunshine/*.list | grep -nE "$forbidden"; then
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

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "PASS: all checks passed."
else
  echo "FAIL: $ERRORS error(s) found."
  exit 1
fi
