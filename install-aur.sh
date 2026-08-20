#!/bin/bash
# AUR packages. Deliberately the LAST thing the bootstrap runs.
#
# AUR builds from source, so they are by far the slowest and least predictable
# step — a single package can pull a multi-hour dependency chain (an Electron
# app will fetch the whole Chromium tree, ~29M git objects). Running this after
# install-dotfiles.sh means a bad AUR package costs you a package, not your
# entire setup: the terminal, editor, and dotfiles are already in place.
#
# Prefer a `-bin` variant whenever one exists. It repackages an upstream binary
# instead of compiling, which is the difference between seconds and hours.
set -euo pipefail

AUR_PACKAGES=(
  # Cursor theme. Selected by HYPRCURSOR_THEME in the dotfiles' looknfeel.lua —
  # if you rename one, rename the other or you get the default cursor back.
  rose-pine-hyprcursor    # Hyprland-native cursor format
  # rose-pine-cursor      # XCursor format, for XWayland/GTK apps

  # postman-bin             # API client — prebuilt, no compile

  # NOT plain `mongodb-compass`. That PKGBUILD depends on electron37, which
  # builds Chromium from source: a 29M-object clone plus a JDK/Rust/Qt5/LLVM
  # toolchain (~1.2 GB of build deps alone) before compilation even starts.
  # The -bin variant repackages MongoDB's own release binary instead.
  mongodb-compass-bin     # Mongo GUI — prebuilt

  # NOT plain `bruno` — same Electron trap as Compass: it pulls an electronNN
  # and builds Chromium from source.
  bruno-bin               # API client — prebuilt
)

if ((${#AUR_PACKAGES[@]} == 0)); then
  echo "No AUR packages configured."
  exit 0
fi

# One bad name fails the whole batch, so fall back to installing individually —
# the rest still land and the failure gets named.
echo "Installing from AUR: ${AUR_PACKAGES[*]}"
if ! omarchy-pkg-aur-add "${AUR_PACKAGES[@]}"; then
  echo "warning: batch AUR install failed — retrying individually" >&2
  for pkg in "${AUR_PACKAGES[@]}"; do
    omarchy-pkg-aur-add "$pkg" || echo "warning: '$pkg' failed to install" >&2
  done
fi
