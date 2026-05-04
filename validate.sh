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

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "PASS: all checks passed."
else
  echo "FAIL: $ERRORS error(s) found."
  exit 1
fi
