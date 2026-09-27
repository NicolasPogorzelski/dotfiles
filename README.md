# dotfiles

Personal developer environment configuration. One `git clone` + `./install.sh`
to reproduce the setup on any machine.

## What this manages

- `.gitconfig` - user identity, default branch, pull/rebase, editor
- `~/.claude/settings.json` - global Claude Code settings and hooks
- `~/git/homelab-server-architecture/.claude/settings.local.json` - project-local Claude Code hooks

## Structure

```
dotfiles/
├── bootstrap.sh                        # installs apt packages, ansible, claude code
├── install.sh                          # renders templates and writes config files
├── validate.sh                         # checks template integrity before install
├── scripts/
│   └── workstation/
│       ├── sync-gdm-wallpaper.sh       # sync latest Bing wallpaper to the GDM login screen
│       └── sunshine/
│           ├── sunshine-display-mode.sh # display layouts: desk / stream (120 Hz dummy) / rollback
│           ├── mangohud-fps-mode.sh    # MangoHud FPS limit: 60 while streaming, 72 at the desk
│           └── reset-desk-state.conf   # systemd drop-in: restore desk state on Sunshine start
└── templates/
    ├── gitconfig                       # ~/.gitconfig
    ├── claude-global-settings.json     # ~/.claude/settings.json
    └── homelab-settings.local.json     # ~/git/homelab-server-architecture/.claude/settings.local.json
```

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

## Paths on rpm-ostree systems

`install.sh` resolves the repository path with `readlink -f`, so the rendered hook path is
the physical `/var/home/...` form rather than the `$HOME` form. On Bazzite and Silverblue
`/home` is a symlink to `/var/home`, and a hook path in the logical form compared
unequal to what `git rev-parse --show-toplevel` returns, which silently disabled the
commit guard.

## Workstation scripts

Standalone helpers - not run by `install.sh`:

- `scripts/workstation/sync-gdm-wallpaper.sh` - copies the latest image downloaded by
  the Bing Wallpaper GNOME extension to the GDM login screen background via dconf
  (CachyOS/GNOME). Set `WALLPAPER_USER_HOME` at the top first, then run as root:
  `sudo ./scripts/workstation/sync-gdm-wallpaper.sh`.

### Sunshine game streaming (Bazzite gaming PC)

Streaming goes to a TV through an HDMI dummy plug (`HDMI-1`); the desk monitor (`DP-1`) runs
75 Hz with VRR. Capture uses the XDG portal (PipeWire), so GNOME hands each finished frame to
Sunshine instead of Sunshine reading the framebuffer through KMS on its own clock. Background
and measurements:
[devops-til: Game Streaming Stutter](https://github.com/NicolasPogorzelski/devops-til/blob/main/applications/game-streaming-stutter.md).

- `scripts/workstation/sunshine/sunshine-display-mode.sh desk|stream|stream-both|kms-desk` -
  all display layouts in one place. Portal consent is bound to one monitor, so the dummy plug
  exists in every layout and only `DP-1` comes and goes:
  - `desk` - `DP-1` primary, dummy at 60 Hz right of it (an invisible second monitor)
  - `stream` - dummy only, 4K **120 Hz** HDR (`bt2100`). Games stay capped at 60 FPS; a missed
    compositor refresh then costs 8.3 ms instead of 16.7 ms
  - `stream-both` - fallback that keeps `DP-1` on while streaming
  - `kms-desk` - `DP-1` only, the old layout for rolling back to KMS capture
  `gdctl` is called with `LD_LIBRARY_PATH` removed: the Sunshine unit exports Homebrew's lib
  directory, which makes `/usr/bin/python3` load Homebrew's libpython and fail with
  `No module named 'gi'`.
- `scripts/workstation/sunshine/mangohud-fps-mode.sh stream|desk` - sets `fps_limit` and
  `fps_limit_method` in every goverlay per-game MangoHud config and in
  `~/.config/MangoHud/MangoHud.conf`: `stream` = 60 / `early` (even frame delivery),
  `desk` = 72 / `late` (below the 75 Hz VRR ceiling, lowest latency). MangoHud reloads its
  config on change, so a running game picks it up live. Games without MangoHud are not
  covered - cap them to 60 FPS in-game, or they run at 120 on the 120 Hz dummy.
- `scripts/workstation/sunshine/reset-desk-state.conf` - drop-in for the Sunshine user unit.
  On every start no client is connected, so it restores `desk` and the desk FPS limit. This
  covers sessions whose `undo` never ran (crash, reboot mid-stream). The `-` prefix keeps a
  failing restore from blocking the start.

Install:

```bash
install -m 755 scripts/workstation/sunshine/sunshine-display-mode.sh ~/.local/bin/sunshine-display-mode
install -m 755 scripts/workstation/sunshine/mangohud-fps-mode.sh ~/.local/bin/mangohud-fps-mode
install -m 644 scripts/workstation/sunshine/reset-desk-state.conf \
  ~/.config/systemd/user/app-dev.lizardbyte.app.Sunshine.service.d/reset-desk-state.conf
systemctl --user daemon-reload
```

`~/.config/sunshine/sunshine.conf` (prep commands run in order on connect and in reverse on
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
