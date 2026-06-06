# dotfiles

Personal developer environment configuration. One `git clone` + `./install.sh`
to reproduce the setup on any machine.

## What this manages

- `.gitconfig` — user identity, default branch, pull/rebase, editor
- `~/.claude/settings.json` — global Claude Code settings and hooks
- `~/git/homelab-server-architecture/.claude/settings.local.json` — project-local Claude Code hooks

## Structure

```
dotfiles/
├── bootstrap.sh                        # installs apt packages, ansible, claude code
├── install.sh                          # renders templates and writes config files
├── validate.sh                         # checks template integrity before install
├── scripts/
│   └── workstation/
│       └── sync-gdm-wallpaper.sh       # sync latest Bing wallpaper to the GDM login screen
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
./install.sh --dry-run # preview what will be written
./install.sh           # apply
```

## Workstation scripts

Standalone helpers — not run by `install.sh`:

- `scripts/workstation/sync-gdm-wallpaper.sh` — copies the latest image downloaded by
  the Bing Wallpaper GNOME extension to the GDM login screen background via dconf
  (CachyOS/GNOME). Set `WALLPAPER_USER_HOME` at the top first, then run as root:
  `sudo ./scripts/workstation/sync-gdm-wallpaper.sh`.

## Prerequisites

- `python3` available on the target machine
- `~/git/homelab-server-architecture` cloned and present
- Claude Code installed
