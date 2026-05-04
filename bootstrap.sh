#!/usr/bin/env bash
set -e

echo "=== bootstrap LXC250 ==="
echo ""

# System packages
echo "Installing apt packages..."
sudo apt-get update -qq
sudo apt-get install -y git curl python3 python3-venv pipx tmux

# Make pipx-installed binaries available in PATH
pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"

# Ansible
echo "Installing Ansible via pipx..."
if pipx list | grep -q ansible; then
  echo "  already installed, skipping"
else
  pipx install ansible
fi

# Claude Code
echo "Installing Claude Code..."
if command -v claude &>/dev/null; then
  echo "  already installed ($(claude --version)), skipping"
else
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo ""
echo "Done. Run install.sh next to apply config files."
echo "NOTE: SSH key and Tailscale auth must be set up manually."
echo "      See runbooks/platform/lxc250-rebuild.md"
