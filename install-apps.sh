#!/bin/bash
# Software installed through Omarchy's own installers.
#
# These do more than `pacman -S` — they wire up themes, defaults, secrets and
# services. Always prefer one of these over a raw package install.
#
# See everything available:  omarchy install
# See what a command does:   omarchy install dev-env --help
set -euo pipefail

# Each entry is passed verbatim to `omarchy install`.
APPS=(
  # "editor-vscode"        # VS Code + Omarchy theme, secrets, auto-update off
  # "dev-env node"         # via mise
  # "dev-env ruby"
  # "dev-env python"
  # "docker-dbs"           # Postgres/MySQL/Redis in Docker
  # "service-tailscale"
  # "service-1password"
)

if ((${#APPS[@]} == 0)); then
  echo "No Omarchy apps configured."
  exit 0
fi

for app in "${APPS[@]}"; do
  echo "──  omarchy install $app"
  # shellcheck disable=SC2086
  omarchy install $app || echo "warning: 'omarchy install $app' failed" >&2
done

# Set defaults once the apps exist. Uncomment what applies.
# omarchy default editor code
# omarchy default terminal alacritty
# omarchy default browser chromium
