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

# Check 3: install.sh is executable
echo "Check 3: install.sh is executable"
if [ -x install.sh ]; then
  echo "  OK: install.sh"
else
  echo "  FAIL: install.sh is not executable (run: chmod +x install.sh)"
  ERRORS=$((ERRORS+1))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "PASS: all checks passed."
else
  echo "FAIL: $ERRORS error(s) found."
  exit 1
fi
