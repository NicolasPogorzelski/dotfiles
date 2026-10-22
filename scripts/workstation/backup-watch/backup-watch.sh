#!/usr/bin/env bash
# Daily reminder that the dotfiles backup is behind: runs sync-all.sh --check and
# install.sh --check and looks for uncommitted or unpushed work in the repo; says so in a
# desktop notification and stays quiet otherwise. Changes nothing. Started by
# backup-watch.timer (systemd --user).
set -uo pipefail

repo="${DOTFILES_DIR:-$HOME/git/dotfiles}"
[ -d "$repo/.git" ] || { echo "no dotfiles clone at $repo"; exit 1; }

msgs=()
out=$("$repo/scripts/workstation/sync-all.sh" --check 2>&1)
echo "$out"
drifted=$(sed -n 's/^DRIFTED: \(.*\) -> .*/\1/p' <<<"$out")
[ -z "$drifted" ] || msgs+=("Live geaendert, nicht gesichert: $drifted -> sync-all.sh, dann committen")

# Git and Claude Code configuration: a live file that left its template was changed by
# hand or by Claude Code itself, and the next install.sh would undo it.
out=$("$repo/install.sh" --check 2>&1)
echo "$out"
# install.sh names the homelab file by its physical /var/home path, so both forms shorten.
drifted=$(sed -n 's|^DRIFTED: ||p' <<<"$out" | sed "s|^\(/var\)\{0,1\}$HOME/|~/|" | paste -sd ' ')
[ -z "$drifted" ] || msgs+=("Weicht von dotfiles ab: $drifted -> Vorlage anpassen oder install.sh")

changes=$(git -C "$repo" status --porcelain | wc -l)
[ "$changes" -eq 0 ] || msgs+=("$changes nicht committete Aenderung(en) im Repo")

git -C "$repo" fetch -q 2>/dev/null
ahead=$(git -C "$repo" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
[ "$ahead" -eq 0 ] || msgs+=("$ahead Commit(s) nicht gepusht")

[ ${#msgs[@]} -eq 0 ] && { echo "backup current"; exit 0; }
printf '%s\n' "${msgs[@]}"
notify-send -a dotfiles -i dialog-warning "Workstation-Backup nicht aktuell" "$(printf '%s\n' "${msgs[@]}")" 2>/dev/null
exit 0
