#!/bin/bash
# Extra Arch packages beyond Omarchy's base set.
#
# Before adding anything, check Omarchy doesn't already ship it:
#   pacman -Q <package>
#   grep -x <package> /usr/share/omarchy/install/omarchy-base.packages
#
# Already in Omarchy 4.0.0 base — do NOT add these (verified against
# omarchy-base.packages, not assumed):
#   tmux mise starship fzf zoxide lazygit git jq nvim foot yay
#   docker docker-compose docker-buildx lazydocker
#   ripgrep fd bat eza
#
# NOT in base, despite what you may assume:
#   alacritty ghostty kitty gh
# Alacritty has an Omarchy installer, so it belongs in install-apps.sh
# ("terminal alacritty") rather than here — that also sets it as the default.
set -euo pipefail

# Official Arch repos. omarchy-pkg-add wraps `pacman -S --noconfirm --needed`.
PACKAGES=(
  gh                      # GitHub CLI; not in base
  ttf-cascadia-mono-nerd  # hard-referenced by the stowed alacritty.toml

  # android-tools         # adb/fastboot — enough for Expo Go on a real device
  # httpie
  # yazi
)

# AUR. Slower (builds from source) — prefer the official repos when possible.
AUR_PACKAGES=(
  # bruno-bin             # local-first API client
  # mongodb-compass       # GUI; the VS Code Mongo extension covers most of it
)

if ((${#PACKAGES[@]})); then
  echo "Installing: ${PACKAGES[*]}"
  omarchy-pkg-add "${PACKAGES[@]}"
else
  echo "No extra repo packages configured."
fi

if ((${#AUR_PACKAGES[@]})); then
  echo "Installing from AUR: ${AUR_PACKAGES[*]}"
  omarchy-pkg-aur-add "${AUR_PACKAGES[@]}"
else
  echo "No AUR packages configured."
fi
