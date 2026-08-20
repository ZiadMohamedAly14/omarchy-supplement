#!/bin/bash
# Bootstrap a fresh Omarchy 4 machine. Safe to re-run.
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() {
  echo
  echo "──▶ $1"
  bash "./$1" || {
    echo "✗ $1 failed" >&2
    exit 1
  }
}

# Order matters:
#   - preflight refreshes pacman's databases; without it every install below
#     dies with "error: target not found" on a fresh machine
#   - preinstalls are stripped next, so install-packages.sh can put back the
#     few worth keeping (it removes some base packages too — see that script)
#   - stow must exist before dotfiles are linked
run preflight.sh
run remove-preinstalls.sh
run install-stow.sh
run install-packages.sh
run install-apps.sh
run install-plugins.sh
run install-dotfiles.sh
# AUR last: source builds are the slowest and least predictable step, so a bad
# package costs a package rather than the whole setup.
run install-aur.sh

cat <<'DONE'

✓ Bootstrap complete.

  Log out and back in to pick up shell and session changes.
  Hyprland config changes apply with: hyprctl reload
DONE
