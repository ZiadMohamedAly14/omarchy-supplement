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
#   - preinstalls are stripped first, so install-packages.sh can put back the
#     few worth keeping (it removes some base packages too — see that script)
#   - stow must exist before dotfiles are linked
run remove-preinstalls.sh
run install-stow.sh
run install-packages.sh
run install-apps.sh
run install-dotfiles.sh

cat <<'DONE'

✓ Bootstrap complete.

  Log out and back in to pick up shell and session changes.
  Hyprland config changes apply with: hyprctl reload
DONE
