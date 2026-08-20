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
  # --- put back after remove-preinstalls.sh -------------------------------
  # Omarchy ships these by default, but `omarchy remove preinstalls` takes them
  # out with everything else. They are listed here, not skipped as "already in
  # base", precisely because that script runs first.
  omacalc
  omacut
  omawrite
  cliamp
  lazydocker              # IS in omarchy-base.packages, and is still removed
  qt6-multimedia          # cliamp pulls these; listed so a later orphan
  qt6-multimedia-ffmpeg   # prune can't take them back out

  # --- genuinely additional ----------------------------------------------
  # No font package here on purpose — the stowed alacritty.toml uses
  # JetBrainsMono Nerd Font, which Omarchy already ships.
  discord                 # in `extra`, so no AUR build needed

  # android-tools         # adb/fastboot — enough for Expo Go on a real device
  # httpie
  # yazi
)

# AUR packages live in install-aur.sh, which runs LAST — after the dotfiles are
# stowed — so a slow or broken source build cannot cost you the whole setup.

# One bad package name fails the whole pacman transaction, and install-all.sh
# treats a failed child as fatal — so a single typo here would abort the run
# before install-dotfiles.sh, which is the part actually worth having.
#
# Batch first (one transaction, fast), then fall back to installing one at a
# time so the rest still land and the failure is named.
install_batch() {
  local cmd=$1 label=$2
  shift 2
  (($#)) || {
    echo "No $label packages configured."
    return 0
  }

  echo "Installing $label: $*"
  "$cmd" "$@" && return 0

  echo "warning: batch $label install failed — retrying individually" >&2
  local pkg
  for pkg in "$@"; do
    "$cmd" "$pkg" || echo "warning: '$pkg' failed to install" >&2
  done
}

install_batch omarchy-pkg-add repo "${PACKAGES[@]}"
