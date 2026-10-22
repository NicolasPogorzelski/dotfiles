#!/usr/bin/env bash
# PreToolUse-Hook (Bash): Veroeffentlichen ist dem Nutzer vorbehalten (Regel seit 2026-08-17),
# gelockert am 2026-10-13: Claude darf Feature-Branches pushen, nie main.
#
# Erlaubt:  git [-C <repo>] push [-u|--set-upstream] origin <namespace>/<name>
#           (namespace = feat|fix|docs|chore|refactor|test|ci), dazu wie bisher
#           git -C ~/git/overthewire-bandit push.
# Gesperrt: jeder andere push - main/master, HEAD, nackt, refspecs mit ':', --force*, -f,
#           --delete, -d, --tags, --all, --mirror; ausserdem gh pr (create|edit|merge|...),
#           gh release, schreibende gh api, gh repo create --push.
# Zweite Schicht auf GitHub: Ruleset "main-protection" (kein Push ohne PR, kein Force-Push,
# kein Loeschen, keine Bypass-Akteure).

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' \
    "Publishing guard (2026-10-13): Claude may push feature branches (feat/fix/docs/chore/refactor/test/ci) to origin, never main, never force/delete/tags, and never create, edit, merge, comment on or close a pull request. $1"
  exit 0
}

# Fail-closed: kann die Eingabe nicht gelesen werden, wird gesperrt.
input="$(cat)"
cmd="$(jq -er '.tool_input.command // ""' <<<"$input")" || deny "Hook input unreadable."

if grep -qE '(gh[[:space:]]+pr[[:space:]]+(create|edit|merge|comment|review|close|reopen|ready))|(gh[[:space:]]+release)|(gh[[:space:]]+api[^|;&]*(POST|PATCH|PUT|DELETE))|(gh[[:space:]]+repo[[:space:]]+create[^|;&]*--push)' <<<"$cmd"; then
  deny "Pull requests and releases are the user's."
fi

# Freigegebenes Repo in jeder Schreibweise: ~, $HOME, und physisch (rpm-ostree: /home -> /var/home).
bandit_forms=("~/git/overthewire-bandit" "$HOME/git/overthewire-bandit")
physical="$(readlink -f "$HOME/git/overthewire-bandit" 2>/dev/null)" && bandit_forms+=("$physical")

branch_re='^(feat|fix|docs|chore|refactor|test|ci)/[A-Za-z0-9._-]+$'

# Jede git-push-Stelle einzeln pruefen; eine einzige fremde reicht zum Sperren.
while IFS= read -r seg; do
  [[ -z "$seg" ]] && continue
  seg="${seg%"${seg##*[![:space:]]}"}"   # trailing whitespace

  # Bandit: unveraendert erlaubt.
  if [[ "$seg" =~ ^git[[:space:]]+-C[[:space:]]+(.+)[[:space:]]+push$ ]]; then
    for form in "${bandit_forms[@]}"; do
      [[ "${BASH_REMATCH[1]%/}" == "$form" ]] && continue 2
    done
  fi

  # Feature-Branch: genau ein Ziel, origin, benannter Branch, kein Force/Delete/Refspec.
  if [[ "$seg" =~ ^git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]]+(-u|--set-upstream))?[[:space:]]+origin[[:space:]]+([^[:space:]]+)$ ]]; then
    branch="${BASH_REMATCH[4]}"
    [[ "$branch" =~ $branch_re ]] && continue
    deny "Branch '$branch' is not a namespaced feature branch."
  fi

  deny "Push form not allowed: '$seg'. Print the command for the user instead."
# Breit erkennen (auch git -c x=y push, git --git-dir=... push), streng erlauben: alles, was
# nicht exakt einer der beiden Formen oben entspricht, wird gesperrt.
done < <(grep -oE 'git[^|;&]*[[:space:]]push([[:space:]][^|;&]*)?' <<<"$cmd")

exit 0
