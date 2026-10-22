#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=false

# The physical path, symlinks resolved. On rpm-ostree systems /home is a
# symlink to /var/home, and a hook path rendered from $HOME would be the
# logical form; the guard it points at compares repository roots that git
# resolves physically, so the two must agree. readlink -f settles it once.
REPO_PATH="$(readlink -f "$HOME/git/homelab-server-architecture")"

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
  echo "[dry-run mode - no files will be written]"
  echo ""
fi

render() {
  sed -e "s|<repo-path>|$REPO_PATH|g" -e "s|<home>|$HOME|g" "$1"
}

# What the live file has and the template lacks is either a change to port
# back or a reason not to install. The project file's permissions.allow list
# is left out of the comparison: Claude Code appends to it per machine, and
# it is not template material.
show_diff() {
  local template="$1"
  local destination="$2"
  if [ ! -f "$destination" ]; then
    echo "  new file (nothing to compare)"
    return
  fi
  case "$destination" in
    *.json)
      diff <(render "$template" | jq -S 'del(.permissions.allow)') \
           <(jq -S 'del(.permissions.allow)' "$destination") \
        && echo "  identical (allow list excluded)"
      ;;
    *)
      diff <(render "$template") "$destination" && echo "  identical"
      ;;
  esac
}

write_file() {
  local template="$1"
  local destination="$2"
  if $DRY_RUN; then
    echo "[dry-run] would write: $destination"
    show_diff "$template" "$destination" || true
  else
    mkdir -p "$(dirname "$destination")"
    render "$template" > "$destination"
  fi
}

echo "=== dotfiles install ==="
echo "Dotfiles dir : $DOTFILES_DIR"
echo "Homelab repo : $REPO_PATH"
echo ""

write_file "$DOTFILES_DIR/templates/gitconfig" "$HOME/.gitconfig"
write_file "$DOTFILES_DIR/templates/claude-global-settings.json" "$HOME/.claude/settings.json"
write_file "$DOTFILES_DIR/templates/claude-global-CLAUDE.md" "$HOME/.claude/CLAUDE.md"
write_file "$DOTFILES_DIR/templates/claude-hooks/publish-guard.sh" "$HOME/.claude/hooks/publish-guard.sh"
write_file "$DOTFILES_DIR/templates/homelab-settings.local.json" "$REPO_PATH/.claude/settings.local.json"

# Skills: every file under templates/claude-skills/ lands at the same relative
# path under ~/.claude/skills/, so a new role is one new file and no edit here.
while IFS= read -r -d '' skill_file; do
  write_file "$skill_file" "$HOME/.claude/skills/${skill_file#"$DOTFILES_DIR/templates/claude-skills/"}"
done < <(find "$DOTFILES_DIR/templates/claude-skills" -type f -print0 | sort -z)

if ! $DRY_RUN; then
  echo ""
  echo "Validating output..."
  python3 -m json.tool "$HOME/.claude/settings.json" > /dev/null \
    && echo "OK: ~/.claude/settings.json" \
    || echo "FAIL: ~/.claude/settings.json"
  python3 -m json.tool "$REPO_PATH/.claude/settings.local.json" > /dev/null \
    && echo "OK: $REPO_PATH/.claude/settings.local.json" \
    || echo "FAIL: $REPO_PATH/.claude/settings.local.json"
  echo "OK: ~/.gitconfig"
  echo ""
  echo "Done. Start a new Claude Code session to activate hooks."
else
  echo ""
  echo "Dry-run complete. Run without --dry-run to apply changes."
fi
