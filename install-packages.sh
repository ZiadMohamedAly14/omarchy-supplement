#!/bin/bash
# Extra Arch packages beyond Omarchy's base set.
#
# Before adding anything, check Omarchy doesn't already ship it:
#   pacman -Q <package>
#   grep -x <package> /usr/share/omarchy/install/omarchy-base.packages
#
# Already in Omarchy 4 base — do NOT add these:
#   tmux mise starship fzf zoxide lazygit git jq nvim alacritty foot yay
set -euo pipefail

# Official Arch repos. omarchy-pkg-add wraps `pacman -S --noconfirm --needed`.
PACKAGES=(
  # yazi
  # postgresql
  # httpie
)

# AUR. Slower (builds from source) — prefer the official repos when possible.
AUR_PACKAGES=(
  # ghostty
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
