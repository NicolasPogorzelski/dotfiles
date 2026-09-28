#!/usr/bin/env bash
# PreToolUse-Hook (Bash): Veröffentlichen ist dem Nutzer vorbehalten (Regel seit 2026-08-17).
# Einzige Ausnahme: git -C ~/git/overthewire-bandit push (freigegeben am 2026-09-28).
# Gesperrt bleiben überall: gh pr (create|edit|merge|...), gh release, schreibende gh api,
# gh repo create --push.
# Ein nacktes "git push" braucht hier keine Ausnahme: permissions.deny sperrt es vorher.

deny() {
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Publishing is reserved for the user (rule set 2026-08-17). Claude must never push, nor create/edit/merge/comment on a pull request. Only exception: git -C ~/git/overthewire-bandit push. Print the exact command so the user can run it with ! instead."}}'
  exit 0
}

# Fail-closed: kann die Eingabe nicht gelesen werden, wird gesperrt.
input="$(cat)"
cmd="$(jq -er '.tool_input.command // ""' <<<"$input")" || deny

if grep -qE '(gh[[:space:]]+pr[[:space:]]+(create|edit|merge|comment|review|close|reopen|ready))|(gh[[:space:]]+release)|(gh[[:space:]]+api[^|;&]*(POST|PATCH|PUT|DELETE))|(gh[[:space:]]+repo[[:space:]]+create[^|;&]*--push)' <<<"$cmd"; then
  deny
fi

# Freigegebenes Repo in jeder Schreibweise: ~, $HOME, und physisch (rpm-ostree: /home -> /var/home).
allowed_forms=("~/git/overthewire-bandit" "$HOME/git/overthewire-bandit")
physical="$(readlink -f "$HOME/git/overthewire-bandit" 2>/dev/null)" && allowed_forms+=("$physical")

# Jede git-push-Stelle einzeln prüfen; eine einzige fremde reicht zum Sperren.
while IFS= read -r seg; do
  [[ -z "$seg" ]] && continue
  ok=false
  for form in "${allowed_forms[@]}"; do
    [[ "$seg" =~ ^git[[:space:]]+-C[[:space:]]+(.+)[[:space:]]+push[[:space:]]*$ ]] \
      && [[ "${BASH_REMATCH[1]%/}" == "$form" ]] && ok=true
  done
  $ok || deny
done < <(grep -oE 'git[^|;&]*[[:space:]]push([[:space:]]|$)' <<<"$cmd")

exit 0
