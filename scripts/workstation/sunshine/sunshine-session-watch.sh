#!/usr/bin/env bash
# End Sunshine sessions whose client went away without "Quit app".
# Sunshine only runs the global_prep_cmd undo (desk display layout, 72 FPS
# MangoHud limit) when the app is closed; a plain disconnect keeps the session
# alive for a resume, which leaves the desk in stream mode indefinitely.
#   watch -> follow Sunshine's journal; if the last client disconnects and nobody
#            reconnects within $grace seconds, close the app via Sunshine's API
#   close -> close the running app now (e.g. for a session that is already stuck)
# The web UI password comes from an encrypted credential (systemd-creds --user).
set -euo pipefail

unit=app-dev.lizardbyte.app.Sunshine.service
api=https://localhost:47990/api/apps/close
api_user="admin"
cert="$HOME/.config/sunshine/credentials/cacert.pem"
cred_file="$HOME/.config/sunshine-session-watch/api.cred"
grace=30  # long enough to ride out a Wi-Fi hiccup, short enough to be gone before you sit down

password() {
    if [ -f "${CREDENTIALS_DIRECTORY:-/nonexistent}/sunshine-api" ]; then
        cat "$CREDENTIALS_DIRECTORY/sunshine-api"   # running as the service
    else
        systemd-creds decrypt --user --name=sunshine-api "$cred_file" -   # manual call
    fi
}

close_app() {
    local pin pw code
    # Sunshine's certificate is self-signed for a name other than localhost, so
    # hostname checks are off (-k) and the public key is pinned instead: the
    # password is only ever sent to the process holding Sunshine's private key.
    pin=$(openssl x509 -in "$cert" -pubkey -noout | openssl pkey -pubin -outform der |
          openssl dgst -sha256 -binary | base64)
    pw=$(password)
    pw=${pw//\\/\\\\}; pw=${pw//\"/\\\"}   # escape for the quoted curl config value
    # printf is a builtin: the password reaches curl via stdin (-K -), never argv.
    code=$(printf 'user = "%s:%s"\n' "$api_user" "$pw" |
           curl -sS -k --pinnedpubkey "sha256//$pin" -K - -X POST \
                -o /dev/null -w '%{http_code}' "$api") || true
    if [ "$code" = 200 ]; then
        echo "sunshine-session-watch: app closed, Sunshine runs its undo commands"
    else
        echo "sunshine-session-watch: closing the app failed (HTTP ${code:-none})" >&2
        return 1
    fi
}

watch() {
    local line rc clients=0 deadline=0
    while true; do
        if IFS= read -r -t 1 line; then
            case "$line" in
                *"CLIENT CONNECTED"*)
                    clients=$((clients + 1)); deadline=0 ;;
                *"CLIENT DISCONNECTED"*)
                    # Counter starts at 0 even if we joined mid-session; never go negative.
                    if [ "$clients" -gt 0 ]; then clients=$((clients - 1)); fi
                    if [ "$clients" -eq 0 ]; then
                        deadline=$((SECONDS + grace))
                        echo "sunshine-session-watch: last client gone, closing in ${grace}s unless it reconnects"
                    fi ;;
                *"Executing Undo Cmd"*)
                    deadline=0 ;;  # app was quit normally, nothing to do
            esac
        else
            rc=$?
            if [ "$rc" -le 128 ]; then  # >128 is the 1 s timeout, anything else is EOF
                echo "sunshine-session-watch: journal stream ended" >&2
                exit 1
            fi
        fi
        if [ "$deadline" -ne 0 ] && [ "$SECONDS" -ge "$deadline" ]; then
            deadline=0
            close_app || true  # a failed close must not kill the watcher
        fi
    done < <(journalctl --user -u "$unit" -f -n 0 -o cat)
}

case "${1:-}" in
    watch) watch ;;
    close) close_app ;;
    *) echo "usage: ${0##*/} watch|close" >&2; exit 2 ;;
esac
