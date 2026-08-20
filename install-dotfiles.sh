#!/bin/bash
# Clone the dotfiles repo and symlink it into $HOME with GNU Stow.
#
# Anything Omarchy already put in place is moved to a timestamped backup
# directory first — Stow refuses to overwrite real files, and nothing here
# deletes your data.
set -euo pipefail

REPO_URL="https://github.com/ZiadMohamedAly14/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles" # Stow resolves links relative to this; keep it here.

# Stow packages to deploy. Add a package to the dotfiles repo AND to this list —
# a package missing from this list is never linked.
PACKAGES=(
  bash
  hypr
  alacritty
  starship
  desktop   # ~/.local/share/applications overrides for Electron apps
)

if ! command -v stow &>/dev/null; then
  echo "stow is required. Run ./install-stow.sh first." >&2
  exit 1
fi

# --- get the repo ---------------------------------------------------------
if [[ -d $DOTFILES_DIR/.git ]]; then
  echo "$DOTFILES_DIR exists — pulling latest"
  git -C "$DOTFILES_DIR" pull --ff-only || echo "warning: pull failed, using local state" >&2
elif [[ -e $DOTFILES_DIR ]]; then
  echo "$DOTFILES_DIR exists but is not a git repo. Move it aside and re-run." >&2
  exit 1
else
  git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# --- link each package ----------------------------------------------------
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

for pkg in "${PACKAGES[@]}"; do
  if [[ ! -d $DOTFILES_DIR/$pkg ]]; then
    echo "skipping '$pkg' — no such package in $DOTFILES_DIR"
    continue
  fi

  # Move aside anything real that would block a symlink.
  while IFS= read -r rel; do
    target="$HOME/$rel"
    if [[ -e $target && ! -L $target ]]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"
      mv "$target" "$BACKUP/$rel"
      echo "  backed up ~/$rel"
    fi
  done < <(cd "$DOTFILES_DIR/$pkg" && find . -type f -printf '%P\n')

  stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$pkg"
  echo "✓ stowed $pkg"
done

if [[ -d $BACKUP ]]; then
  echo
  echo "Files Omarchy had already placed were saved to:"
  echo "  $BACKUP"
fi
