# dotfiles

Personal developer environment configuration. One `git clone` + `./install.sh`
to reproduce the setup on any machine.

## What this manages

Currently: Claude Code hook configurations.
Intended to grow: `.gitconfig`, `.bashrc`, SSH config templates, and other
personal tool configs as they are added.

## Structure

```
dotfiles/
├── install.sh                          # renders templates and writes config files
├── validate.sh                         # checks template integrity before install
└── templates/
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

## Prerequisites

- `python3` available on the target machine
- `~/git/homelab-server-architecture` cloned and present
- Claude Code installed
