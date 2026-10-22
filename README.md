# dotfiles

Personal developer environment configuration. One `git clone` + `./install.sh`
to reproduce the setup on any machine.

## What this manages

- `.gitconfig` - user identity, default branch, pull/rebase, editor
- `~/.claude/settings.json` - global Claude Code settings and hooks
- `~/.claude/CLAUDE.md` - global working rules for Claude Code. It imports a profile from a private
  repository (`@~/git/career-plan/claude-profil.md`), so nothing personal is kept here; on a
  machine without that repository the import is simply absent
- `~/.claude/hooks/publish-guard.sh` - the global publish guard the settings call: no push, PR or
  release by Claude; single exception `git -C ~/git/overthewire-bandit push`
- `~/.claude/skills/rolle/` - the `/rolle` command: starts one or more roles (`tutor`, `reviewer`,
  `devsecops`, `pruefer`) that Claude acts from for the rest of the session, see [Roles](#roles)
- `~/git/homelab-server-architecture/.claude/settings.local.json` - project-local permissions
  (the publishing deny list). The project's hooks are tracked in that repository's own
  `.claude/settings.json` and are not managed here
- The Bazzite gaming PC's own setup, one module per topic under `scripts/workstation/` (Sunshine,
  displays, shortcuts, PartyDeck, Craft apps, backup reminder): `restore-all.sh` rebuilds it,
  `sync-all.sh` backs it up - see [Workstation modules](#workstation-modules)

## Structure

```
dotfiles/
├── bootstrap.sh                        # installs apt packages, ansible, claude code
├── install.sh                          # renders templates and writes config files
├── validate.sh                         # checks template integrity before install
├── scripts/
│   └── workstation/
│       ├── restore-all.sh              # restore every module below (--system: their sudo parts too)
│       ├── sync-all.sh                 # back up every module below / --check for drift
│       ├── sync-gdm-wallpaper.sh       # sync latest Bing wallpaper to the GDM login screen
│       ├── backup-watch/
│       │   ├── restore.sh              # install the reminder + enable its timer
│       │   ├── sync-from-live.sh       # copy the live files back in / --check for drift
│       │   ├── files.list              # files under $HOME; read by both scripts above
│       │   ├── backup-watch.sh         # sync-all.sh --check + uncommitted/unpushed -> notification
│       │   ├── backup-watch.service    # user unit running it once
│       │   └── backup-watch.timer      # daily, catches up after downtime
│       ├── displays/
│       │   ├── restore.sh              # Fenster-Heimholer extension
│       │   ├── sync-from-live.sh       # copy the live files back in / --check for drift
│       │   ├── files.list              # extension files under $HOME; read by both scripts above
│       │   └── window-heimholer/       # GNOME extension: windows -> primary monitor (in progress)
│       ├── partydeck/
│       │   ├── restore.sh              # PartyDeck + its GE-Proton from GitHub, starter, tiler, settings
│       │   ├── sync-from-live.sh       # copy the live files back in (@HOME@, SDL backend off) / --check
│       │   ├── files.list              # files under $HOME; read by both scripts above
│       │   ├── partydeck-start.sh      # starter, logs to ~/.local/share/partydeck/last-run.log
│       │   ├── partydeck-layout.sh     # 2-player split: top/bottom <-> left/right (Super+Alt+S)
│       │   ├── partydeck.desktop, partydeck.png # menu entry and icon
│       │   ├── settings.json           # PartyDeck settings (Wayland backend, GE-Proton)
│       │   ├── handlers/               # game handlers (Secrets of Grindea)
│       │   └── tiler/                  # partydeck-tiler GNOME extension + its layout/monitor config
│       ├── shortcuts/
│       │   ├── restore.sh              # add or update every custom shortcut by name
│       │   ├── sync-from-live.sh       # rewrite the list from live / --check, reports unlisted shortcuts
│       │   └── keybindings.list        # GNOME custom shortcuts: name|binding|command
│       ├── craft/
│       │   ├── restore.sh              # install all Craft apps from GitHub + the weekly auto-updater
│       │   ├── sync-from-live.sh       # copy the live updater back in, rewrite apps.list / --check for drift
│       │   ├── apps.list               # which storytold Craft apps are installed
│       │   ├── files.list              # files under $HOME: which goes where; read by both scripts above
│       │   ├── craft-flatpak-update.sh # the updater: GitHub release -> SHA256 check -> flatpak install --user
│       │   ├── craft-flatpak-update.service # user unit running it once
│       │   └── craft-flatpak-update.timer   # weekly, catches up after downtime
│       └── sunshine/
│           ├── restore.sh              # restore the whole setup on a fresh install (--system: sudo part)
│           ├── sync-from-live.sh       # copy the live files back in / --check for drift
│           ├── files.list              # files under $HOME: which goes where; read by both scripts above
│           ├── system.list             # files under /etc (udev rules, EDID), restored by --system
│           ├── gsettings.list          # GNOME settings the stream needs (no blanking, no suspend)
│           ├── sunshine-display-mode.sh # display layouts: desk / stream (120 Hz dummy, phone mode) / rollback
│           ├── mangohud-fps-mode.sh    # MangoHud FPS limit: 72 desk, 60 Shield, 120 Pixel 9
│           ├── mangohud-fps-sync.service # user unit: re-apply that limit to configs goverlay rewrites
│           ├── sunshine-session-watch.sh # close sessions whose client vanished without "Quit"
│           ├── sunshine-session-watch.service # user unit for it, runs alongside Sunshine
│           ├── reset-desk-state.conf   # systemd drop-in: restore desk state on Sunshine start
│           ├── app-dev.lizardbyte.app.Sunshine.service # the Sunshine user unit
│           ├── homebrew-env.conf       # systemd drop-in: Homebrew paths, Vulkan encode, Nice
│           ├── config/                 # sunshine.conf, apps.json, covers, MangoHud.conf
│           ├── system/                 # udev rules: virtual gamepad, uhid, Wake-on-LAN
│           └── edid/                   # dummy plug EDID: original + patched with the Pixel 9 mode
└── templates/
    ├── gitconfig                       # ~/.gitconfig
    ├── claude-global-settings.json     # ~/.claude/settings.json
    ├── claude-global-CLAUDE.md         # ~/.claude/CLAUDE.md
    ├── claude-hooks/
    │   └── publish-guard.sh            # ~/.claude/hooks/publish-guard.sh
    ├── claude-skills/                  # ~/.claude/skills/, same relative paths
    │   └── rolle/
    │       ├── SKILL.md                # /rolle [name ...] | aus
    │       └── rollen/                 # one file per role
    └── homelab-settings.local.json     # ~/git/homelab-server-architecture/.claude/settings.local.json
```

## Roles

Specialised behaviour is started on purpose, per session, and ends with it:

```
/rolle                      # list the roles
/rolle tutor                # one role
/rolle reviewer devsecops   # several; where they conflict, the stricter restriction wins
/rolle aus                  # back to normal
```

| Role | Acts as | Never |
|---|---|---|
| `tutor` | hints in steps, pointers to `man`/`--help`, review of my own attempt | writes commands or code, runs anything |
| `reviewer` | critical review of designs and ADRs | writes or edits documents, decides |
| `devsecops` | review from four seats (IT security, OT security, DevSecOps, DevOps), measured | changes anything without approval per ID |
| `pruefer` | oral exam or technical interview, one question at a time, honest grading | gives hints before the answer |

A role overrides the behavioural defaults in CLAUDE.md for that session; publishing rules,
commit rules and the hooks stay in force. Adding a role is one file in `rollen/`.

Until 2026-10-22, learning mode and the review from four seats were standing rules in the global
CLAUDE.md, and two hooks (an explain-every-flag reminder after each tool call, a 15-minute rule on
each prompt) enforced the first. They applied to every session, learning or not. The hooks are
gone; the rules live in `tutor` and `devsecops`, and the global CLAUDE.md keeps only a one-line
duty to name a risk noticed in passing.

## Usage

```bash
git clone git@github.com:NicolasPogorzelski/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./validate.sh          # verify templates are intact
./install.sh --dry-run # diff each template against the live file it would replace
./install.sh           # apply
```

Read the dry-run before applying. Anything the live file has and the template lacks is
either a change to port back into the template or a reason not to run the installer;
running it regardless downgrades the machine to the template. The comparison leaves out
the project file's `permissions.allow` list, which Claude Code appends to per machine and
which is not template material.

## What the templates deliberately do not carry

- Credential helpers in `~/.gitconfig`. The `gh auth git-credential` entry names a path
  that exists on one machine; each workstation adds its own after install.
- The allow list in `settings.local.json`, for the reason above.
- The SSH signing key and `~/.ssh/allowed_signers`. `~/.gitconfig` names both and signs every
  commit and tag, so on a machine without them each commit fails until they are in place.

## Paths on rpm-ostree systems

`install.sh` resolves the repository path with `readlink -f`, so the rendered hook path is
the physical `/var/home/...` form rather than the `$HOME` form. On Bazzite and Silverblue
`/home` is a symlink to `/var/home`, and a hook path in the logical form compared
unequal to what `git rev-parse --show-toplevel` returns, which silently disabled the
commit guard.

## Workstation modules

Everything under `scripts/workstation/` that sets up the Bazzite gaming PC is a module: one
directory per topic. Not run by `install.sh`.

**Restore after losing the machine**, all of it in one go:

```bash
git clone https://github.com/NicolasPogorzelski/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
scripts/workstation/restore-all.sh            # every module's user part
scripts/workstation/restore-all.sh --system   # then the sudo parts (Sunshine), reboot afterwards
```

Prerequisites a module cannot install itself are named in its section below (Sunshine from
Homebrew, the games in Steam). A failing module does not stop the others; the summary names it,
and running the script again is safe. `restore-all.sh sunshine partydeck` restores only those.

**Keep the backup current:** `scripts/workstation/sync-all.sh --check` lists what drifted in any
module; without `--check` it copies the live state in. Review with `git diff`, commit, push.
`backup-watch` runs that check every day and raises a desktop notification when something
drifted, is not committed or not pushed - so the only routine left is reacting to it.

**The contract** - what makes a directory a module. `restore-all.sh` and `sync-all.sh` find
modules by it, so a new one needs no change anywhere else; `validate.sh` check 6 enforces it.

- `restore.sh` - executable, idempotent, non-interactive, no sudo. Installs what is missing,
  writes the backed-up files, keeps every live file it replaces as `<file>.bak-<date>`, and
  prints the steps it cannot do (logins, passwords, pairing) at the end.
- `restore.sh --system` - optional sudo part (files under `/etc`, kernel arguments).
  `restore-all.sh --system` runs it for every module whose `restore.sh` handles `--system`.
- `sync-from-live.sh [--check]` - executable. Copies the live state into the module; with
  `--check` it changes nothing, prints what drifted and exits 1 on drift.
- `files.list` (usual, not required) - `<path in the module>|<path under $HOME>`, the single
  record of what is backed up. Never list a secret: the repository is public, and `validate.sh`
  check 5 rejects lists naming credentials, tokens, keys, `.env` files or `~/.ssh`.

**A new module:** copy `backup-watch/` (the smallest), rename, list the files, run its
`sync-from-live.sh`, then `./validate.sh` and commit. Modules run in alphabetical order; none
depends on another today.

### Other workstation scripts

- `scripts/workstation/sync-gdm-wallpaper.sh` - copies the latest image downloaded by
  the Bing Wallpaper GNOME extension to the GDM login screen background via dconf
  (CachyOS/GNOME). Set `WALLPAPER_USER_HOME` at the top first, then run as root:
  `sudo ./scripts/workstation/sync-gdm-wallpaper.sh`.

### storytold Craft apps (Bazzite gaming PC)

The Craft apps (CadCraft, WordCraft, PhotoCraft, ...) ship only as Flatpak bundles on their
GitHub releases (`storytold/<name>`), not on Flathub. A bundle has no update source, so
`flatpak update` never touches them; a user timer does it instead.

**Restore after losing the machine** (fresh Bazzite, nothing else needed):

```bash
scripts/workstation/craft/restore.sh
```

It puts the updater and its units in place, adds the Flathub user remote (the bundles take
their `org.freedesktop.Platform` runtime from there), downloads every app in `apps.list` in its
latest release, checks it against the release's `SHA256SUMS.txt`, installs it with
`flatpak install --user` and enables the timer. Running it again is safe: installed apps are
only updated. Not backed up: what the apps store in `~/.var/app/ai.storyteller.*` (your own
data, not public material) and the documents you make with them.

**How updating works:** `craft-flatpak-update.timer` fires weekly (`OnCalendar=weekly`, Monday
00:00 plus up to 10 min random delay); `Persistent=true` catches up a missed run at the next
login. The script asks the GitHub API for each installed `ai.storyteller.*` app's latest release,
installs it if the version is newer and the checksum matches, and reports the result with a
desktop notification (critical on failure). It finds new apps by their ID, so a newly installed
Craft app is updated without touching the updater. Log: `journalctl --user -u craft-flatpak-update`;
run it now: `systemctl --user start craft-flatpak-update.service`.

**Keep the backup current** after installing a new Craft app or editing the updater:
`scripts/workstation/craft/sync-from-live.sh --check` lists what drifted, without `--check` it
copies the files in and rewrites `apps.list`; review and commit.

### Display helpers (Bazzite gaming PC)

Switching between the desk layout and the Sunshine dummy (see below) leaves windows on the
invisible HDMI-1 dummy. Two helpers deal with that, the extension in this module and a shortcut
in `shortcuts/`:

- **Fenster-Heimholer** (`window-heimholer@nicolas`) - **in progress: not tested live yet**
  (needs a re-login first). A GNOME extension that moves app windows
  to the current primary monitor: new windows on their first frame, all windows 1.5 s after a
  monitor change, all windows on `Super+Shift+1`. Dialogs follow their parent, gamescope windows
  are left to the PartyDeck tiler. Log: `journalctl --user -b -g window-heimholer`.
- **`Super+Alt+D`**, a custom shortcut making the ultrawide (DP-1) the only display, for when the
  picture is stuck on the dummy (see [Custom shortcuts](#custom-shortcuts)).

**Restore:** `scripts/workstation/displays/restore.sh`, then log out and in once (GNOME on
Wayland loads a new extension only at login).

**Keep the backup current** after editing the extension:
`scripts/workstation/displays/sync-from-live.sh --check` lists what drifted, without `--check` it
copies it in; review and commit.

### Custom shortcuts

`scripts/workstation/shortcuts/keybindings.list` holds every GNOME custom shortcut
(Settings -> Keyboard -> Custom Shortcuts): `Ctrl+Alt+T` terminal, `Ctrl+Alt+Del` (keypad) and
`Ctrl+Shift+Esc` Mission Center, `Super+Alt+D` ultrawide only, `Super+Alt+S` PartyDeck split.
Entries are matched by name, so names must be unique and running `restore.sh` again updates
instead of duplicating. `@HOME@` in a command stands for the home directory, since GNOME runs
the command without a shell. A shortcut created in Settings shows up in
`sync-from-live.sh --check` as "not backed up": add a line with its name, then sync.

### PartyDeck splitscreen (Bazzite gaming PC)

[PartyDeck](https://github.com/partydeck/partydeck) runs several instances of a game side by side,
one controller each. `restore.sh` installs it from the latest release (the SteamOS tarball: the
AppImage lacked `res/goldberg`) when it is missing, and the GE-Proton build `settings.json` names,
checked against its published sha512. PartyDeck itself publishes no checksums. Then it writes
the starter (`partydeck-start`, log in `~/.local/share/partydeck/last-run.log`), menu entry,
settings, the Secrets of Grindea handler and the `partydeck-tiler@nicolas` GNOME extension.

- **Tiler, not KWin:** PartyDeck tiles its windows through a nested KWin, which Bazzite's GNOME
  lacks. The tiler extension places the gamescope windows instead, on the monitor named in
  `~/.config/partydeck-tiler/monitor` (DP-1) in the layout of `.../layout`.
  `Super+Alt+S` (`partydeck-layout`) toggles two players between top/bottom and left/right.
- **SDL backend off:** gamescope on the SDL (XWayland) backend flickers with black tiles here,
  on Wayland it does not. PartyDeck's GUI turns `gamescope_sdl_backend` back on when it saves;
  the backup always stores `false`, and `restore.sh` writes it.
- **Not backed up:** profiles (game saves), Wine prefixes (1+ GB, recreated on first start), the
  games themselves (Steam).
- **Open (2026-10-03):** with two players only one window was visible although both instances
  ran; see the PartyDeck notes before relying on it.

### Sunshine game streaming (Bazzite gaming PC)

**Restore after losing the machine** (Bazzite, Sunshine from Homebrew, dummy plug in HDMI-1):

```bash
brew install lizardbyte/homebrew/sunshine         # tested with 2026.914.233613
flatpak install flathub io.github.benjamimgois.goverlay
scripts/workstation/sunshine/restore.sh           # scripts, units, configs, GNOME settings; enables the services
scripts/workstation/sunshine/restore.sh --system  # udev rules + Pixel 9 EDID + kernel arguments (sudo), then reboot
```

`restore.sh` keeps every live file it replaces as `<file>.bak-<date>` and ends with the steps a
public repo cannot carry: share the dummy in GNOME's dialog, set the web UI password, pair the
Shield and the Pixel again, store the password for the session watcher. Not in this repo on
purpose: `credentials/`, `sunshine_state.json` (paired clients), `portal_token`, `api.cred`.

**Keep the backup current** after changing anything live:
`scripts/workstation/sunshine/sync-from-live.sh --check` lists what drifted, without `--check` it
copies it in; review and commit. Run it at the desk, not mid-stream, so `MangoHud.conf` carries
the desk limit. The three `*.list` files are the single record of what is backed up;
`sync-from-live.sh` refuses to run while `validate.sh` fails, and check 5 there rejects any list
naming one of Sunshine's secrets. The gitleaks workflow scans every commit on GitHub on top of that.

Not part of the backup, because nothing needs changing: MangoHud ships with Bazzite, and
Bazzite's default firewall zone (`FedoraWorkstation`) already allows ports 1025-65535, which
covers Sunshine's 47984-48010. Games get MangoHud through goverlay; set them up there again,
`mangohud-fps-sync.service` then applies the right FPS limit to their new configs.

#### Clients

Moonlight settings that the client detection depends on (set by hand, Moonlight keeps them on
the device):

| Client | Resolution | FPS | HDR | Result on the PC |
|---|---|---|---|---|
| NVIDIA Shield TV Pro 2019 | 4K (3840x2160) | 60 | on | dummy 4K120, FPS cap 60 |
| Pixel 9 | Native (2251x1080) | 120 | on | dummy 2251x1080@120, FPS cap 120 |

Streaming goes to a TV through an HDMI dummy plug (`HDMI-1`); the desk monitor (`DP-1`) runs
75 Hz with VRR. Capture uses the XDG portal (PipeWire), so GNOME hands each finished frame to
Sunshine instead of Sunshine reading the framebuffer through KMS on its own clock. Background
and measurements:
[devops-til: Game Streaming Stutter](https://github.com/NicolasPogorzelski/devops-til/blob/main/applications/game-streaming-stutter.md).

- `scripts/workstation/sunshine/sunshine-display-mode.sh desk|stream|stream-both|kms-desk` -
  all display layouts in one place. Portal consent is bound to one monitor, so the dummy plug
  exists in every layout and only `DP-1` comes and goes:
  - `desk` - `DP-1` primary, dummy at 60 Hz left of it and shifted down (an invisible second
    monitor; the two only touch along a 221 px strip, so the pointer rarely lands on it)
  - `stream` - dummy only, 4K **120 Hz** HDR (`bt2100`). Games stay capped at 60 FPS; a missed
    compositor refresh then costs 8.3 ms instead of 16.7 ms. A client that is not 16:9 (the
    Pixel 9) gets the dummy in exactly its mode at 120 Hz if the patched EDID offers it
    (`restore.sh --system`), otherwise the 4K120 layout
  - `stream-both` - fallback that keeps `DP-1` on while streaming
  - `kms-desk` - `DP-1` only, the old layout for rolling back to KMS capture
  `gdctl` is called with `LD_LIBRARY_PATH` removed: the Sunshine unit exports Homebrew's lib
  directory, which makes `/usr/bin/python3` load Homebrew's libpython and fail with
  `No module named 'gi'`.
- `scripts/workstation/sunshine/mangohud-fps-mode.sh stream|stream-phone|desk|apply|watch` - sets
  `fps_limit` and `fps_limit_method` in every goverlay per-game MangoHud config and in
  `~/.config/MangoHud/MangoHud.conf`: `stream` = 60 / `early` (even frame delivery),
  `desk` = 72 / `late` (below the 75 Hz VRR ceiling, lowest latency). `stream` becomes
  `stream-phone` = 120 / `early` when the client is not 16:9 and asks for 120 FPS (the Pixel 9);
  the Shield always gets 60. Switches are logged to `journalctl -t mangohud-fps-mode`. After
  editing the script, restart `mangohud-fps-sync.service`: its loop keeps the old code. MangoHud reloads its
  config on change, so a running game picks it up live. Games without MangoHud are not
  covered - cap them to 60 FPS in-game, or they run at 120 on the 120 Hz dummy.
  `stream`/`desk` remember the mode in `~/.local/state/mangohud-fps-mode`; `apply`
  re-applies it once, `watch` every 2 s and only writes files that drifted.
- `scripts/workstation/sunshine/mangohud-fps-sync.service` - runs `mangohud-fps-mode watch`.
  goverlay writes a fresh per-game `MangoHud.conf` with `fps_limit=0` (unlimited) whenever a
  game is set up or patched; without this unit that game ran uncapped until the next
  connect or disconnect.
- `scripts/workstation/sunshine/sunshine-session-watch.sh watch|close` and its unit - Sunshine
  runs `undo` only when the app is closed. A client that just disconnects (network drop,
  Moonlight closed without "Quit app") leaves the session open for a resume, and the desk
  stays in stream mode. The watcher follows Sunshine's journal; when the last client is gone
  and nobody reconnects within 30 s it closes the app through the web API
  (`POST /api/apps/close`), so Sunshine runs its own, tested `undo`. A later connect is a fresh
  session with `do`. The web UI password is an encrypted systemd credential, reaches `curl`
  over stdin rather than argv, and is only sent to the pinned public key of Sunshine's
  certificate. `close` ends a stuck session by hand.
- `scripts/workstation/sunshine/reset-desk-state.conf` - drop-in for the Sunshine user unit.
  On every start no client is connected, so it restores `desk` and the desk FPS limit. This
  covers sessions whose `undo` never ran (crash, reboot mid-stream). The `-` prefix keeps a
  failing restore from blocking the start.

Install: `restore.sh` (above) does all of it.

The session watcher stays inactive until its credential exists (`ConditionPathExists=`).
Store the Sunshine web UI password - typed at the prompt, so it never reaches the shell
history - and start the watcher. `api_user` in the script must match the web UI user name.

```bash
install -d -m 700 ~/.config/sunshine-session-watch
systemd-ask-password -n "Sunshine web UI password:" | systemd-creds encrypt --user --name=sunshine-api - ~/.config/sunshine-session-watch/api.cred
systemctl --user restart sunshine-session-watch.service
~/.local/bin/sunshine-session-watch close   # expect "app closed"; HTTP 401 = wrong password
```

After changing the password, encrypt it again and `restart` (not `start`) the watcher: the
service reads the credential only when it starts.

`~/.config/sunshine/sunshine.conf` (full file in `config/`; prep commands run in order on connect and in reverse on
session end; they are executed without a shell, so `&&` chaining does not work):

```
capture = portal
system_tray = disabled
global_prep_cmd = [{"do":"/home/<user>/.local/bin/sunshine-display-mode stream","elevated":"false","undo":"/home/<user>/.local/bin/sunshine-display-mode desk"},{"do":"/home/<user>/.local/bin/mangohud-fps-mode stream","elevated":"false","undo":"/home/<user>/.local/bin/mangohud-fps-mode desk"}]
```

`system_tray = disabled` because the Homebrew build aborts at start when its tray icon cannot
load a display plugin; a background service needs none.

First start after install: switch to `desk` so the dummy exists, restart Sunshine, and in
GNOME's sharing dialog pick the dummy (**LLV 27"**), allow remote interaction, share. The
grant is stored in `~/.config/sunshine/portal_token` and stays valid as long as the dummy
exists. To be asked again, delete that file and restart Sunshine.

Capabilities: portal capture needs none. Only KMS capture (the `kms-desk` rollback) needs
`cap_sys_admin`, and must be reapplied after every `brew upgrade sunshine`. Do not add
`cap_sys_nice`: Sunshine then runs its GPU work at high priority and preempts GNOME's
compositing, which doubled missed display refreshes in measurement.

```bash
sudo setcap cap_sys_admin+p "$(readlink -f /home/linuxbrew/.linuxbrew/opt/sunshine/bin/sunshine)"
```

## Prerequisites

- `python3` and `jq` available on the target machine
- `~/git/homelab-server-architecture` cloned and present
- Claude Code installed
- `ansible-lint` at the version the homelab CI pins, so its pre-commit check is not
  silently inert: `pipx install 'ansible-lint==26.6.0'` where `pipx` exists, or
  `uv tool install 'ansible-lint==26.6.0'` on an immutable Fedora workstation, where
  installing `pipx` itself would need a reboot
