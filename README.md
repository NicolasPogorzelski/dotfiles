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

## Prerequisites

- `python3` and `jq` available on the target machine
- `~/git/homelab-server-architecture` cloned and present
- Claude Code installed
- `ansible-lint` at the version the homelab CI pins, so its pre-commit check is not
  silently inert: `pipx install 'ansible-lint==26.6.0'` where `pipx` exists, or
  `uv tool install 'ansible-lint==26.6.0'` on an immutable Fedora workstation, where
  installing `pipx` itself would need a reboot
