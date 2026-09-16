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

# One password prompt, here, up front — then keep the sudo timestamp alive for
# the whole run. Without the refresh it expires (default 5–15 min) somewhere
# inside `omarchy update` + docker pulls + node install, and yay's `pacman -U`
# at the end re-prompts mid-AUR-build with nobody at the keyboard. The children
# run as the same user on the same tty, so they share this timestamp; none of
# them call `sudo -v` themselves.
#
# `sudo -n` never prompts: if the timestamp has somehow lapsed anyway, the loop
# fails quietly and the next child prompts, which is no worse than before.
sudo -v
(
  while kill -0 "$$" 2>/dev/null; do
    sudo -n true 2>/dev/null
    sleep 50
  done
) &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT

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
run install-webapps.sh
run install-dotfiles.sh
# AUR next-to-last: source builds are the slowest and least predictable step, so
# a bad package costs a package rather than the whole setup.
run install-aur.sh
# Plugins genuinely last: they PROMPT (for API tokens, locations, confirmations)
# and a prompt blocks forever if nobody is at the keyboard. Everything above
# completes unattended before anything can stop and wait.
run install-plugins.sh

cat <<'DONE'

✓ Bootstrap complete.

  Log out and back in to pick up shell and session changes.
  Hyprland config changes apply with: hyprctl reload
DONE
