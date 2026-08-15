#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_PATH="$HOME/git/homelab-server-architecture"
DRY_RUN=false

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
  echo "[dry-run mode - no files will be written]"
  echo ""
fi

write_file() {
  local template="$1"
  local destination="$2"
  if $DRY_RUN; then
    echo "[dry-run] would write: $destination"
  else
    mkdir -p "$(dirname "$destination")"
    sed "s|<repo-path>|$REPO_PATH|g" "$template" > "$destination"
  fi
}

echo "=== dotfiles install ==="
echo "Dotfiles dir : $DOTFILES_DIR"
echo "Homelab repo : $REPO_PATH"
echo ""

write_file "$DOTFILES_DIR/templates/gitconfig" "$HOME/.gitconfig"
write_file "$DOTFILES_DIR/templates/claude-global-settings.json" "$HOME/.claude/settings.json"
write_file "$DOTFILES_DIR/templates/homelab-settings.local.json" "$REPO_PATH/.claude/settings.local.json"

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
