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

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Official Arch repos. omarchy-pkg-add wraps `pacman -S --noconfirm --needed`.
PACKAGES=(
  # --- put back after remove-preinstalls.sh -------------------------------
  # Omarchy ships these by default, but `omarchy remove preinstalls` takes them
  # out with everything else. They are listed here, not skipped as "already in
  # base", precisely because that script runs first.
  #
  # Not everything it removes comes back: cliamp (and the qt6-multimedia pair it
  # drags in) is left out on purpose.
  omacalc
  omacut
  omawrite
  lazydocker              # IS in omarchy-base.packages, and is still removed

  # --- genuinely additional ----------------------------------------------
  # System monospace font. install-apps.sh runs `omarchy-font-set` to select
  # it, and the stowed alacritty.toml names it explicitly — all three must
  # agree. (Omarchy's own default, JetBrainsMono Nerd Font, stays installed.)
  ttf-cascadia-mono-nerd

  # Native Discord, not the Omarchy web app (which remove-preinstalls.sh strips
  # and install-webapps.sh deliberately does not restore).
  discord

  # Not in base. Omarchy ships `gh` only as a mise stub in ~/.local/bin, and
  # remove-preinstalls.sh deletes that stub — so this is the real package.
  github-cli

  yazi                    # TUI file manager

  # android-tools         # adb/fastboot — enough for Expo Go on a real device
  # httpie
)

# AUR packages live in install-aur.sh, which runs LAST — after the dotfiles are
# stowed — so a slow or broken source build cannot cost you the whole setup.

install_batch omarchy-pkg-add repo "${PACKAGES[@]}"
