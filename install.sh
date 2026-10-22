#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE=apply

# The physical path, symlinks resolved. On rpm-ostree systems /home is a
# symlink to /var/home, and a hook path rendered from $HOME would be the
# logical form; the guard it points at compares repository roots that git
# resolves physically, so the two must agree. readlink -f settles it once.
REPO_PATH="$(readlink -f "$HOME/git/homelab-server-architecture")"

case "${1:-}" in
  --dry-run)
    MODE=dry-run
    echo "[dry-run mode - no files will be written]"
    echo ""
    ;;
  # Quiet drift report for backup-watch: one "DRIFTED: <file>" line per live file
  # that differs from its template, exit 1 if any does. Writes nothing.
  --check) MODE=check ;;
esac

DRIFT=0

render() {
  sed -e "s|<repo-path>|$REPO_PATH|g" -e "s|<home>|$HOME|g" "$1"
}

# The template as it would land on this machine. A JSON file keeps the machine's
# permissions.allow entries next to the template's: Claude Code appends to that list
# per machine, and an install that replaced it would take back every approval.
render_for() {
  local template="$1"
  local destination="$2"
  if [[ "$destination" == *.json && -f "$destination" ]]; then
    render "$template" | jq --indent 2 --slurpfile live "$destination" '
      ((.permissions.allow // []) + ($live[0].permissions.allow // [])) as $allow
      | if $allow == [] then . else .permissions.allow = ($allow | unique) end'
  else
    render "$template"
  fi
}

# JSON is compared with sorted keys and a sorted allow list, so the order Claude Code
# writes in is no drift.
normalized() {
  case "$1" in
    *.json) jq -S 'if .permissions.allow then .permissions.allow |= sort else . end' ;;
    *) cat ;;
  esac
}

# What the live file has and the template lacks is either a change to port
# back or a reason not to install.
show_diff() {
  local template="$1"
  local destination="$2"
  if [ ! -f "$destination" ]; then
    echo "  new file (nothing to compare)"
    return
  fi
  diff <(render_for "$template" "$destination" | normalized "$destination") \
       <(normalized "$destination" < "$destination") \
    && echo "  identical"
}

write_file() {
  local template="$1"
  local destination="$2"
  case "$MODE" in
    dry-run)
      echo "[dry-run] would write: $destination"
      show_diff "$template" "$destination" || true
      ;;
    check)
      if [ ! -f "$destination" ] || ! cmp -s \
          <(render_for "$template" "$destination" | normalized "$destination") \
          <(normalized "$destination" < "$destination"); then
        echo "DRIFTED: $destination"
        DRIFT=1
      fi
      ;;
    apply)
      mkdir -p "$(dirname "$destination")"
      # Rendered into a variable first: render_for reads the live file, and a direct
      # redirect would truncate it before it is read.
      local rendered
      rendered="$(render_for "$template" "$destination")"
      printf '%s\n' "$rendered" > "$destination"
      ;;
  esac
}

if [ "$MODE" != check ]; then
  echo "=== dotfiles install ==="
  echo "Dotfiles dir : $DOTFILES_DIR"
  echo "Homelab repo : $REPO_PATH"
  echo ""
fi

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

if [ "$MODE" = check ]; then
  exit "$DRIFT"
elif [ "$MODE" = apply ]; then
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
