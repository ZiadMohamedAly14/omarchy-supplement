# Shared helpers for the install-*.sh scripts (source this, don't run it).
#
# install-all.sh still EXECUTES each child; only this file is sourced, from
# inside a child, so a failure here still cannot reach the parent shell.
#
#   source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# install_batch <cmd> <label> <pkg>...
#
# One bad package name fails the whole pacman/yay transaction, and
# install-all.sh treats a failed child as fatal — so a single typo in a list
# would abort the run before install-dotfiles.sh, which is the part actually
# worth having.
#
# Batch first (one transaction, fast), then fall back to installing one at a
# time so the rest still land and the failure is named. <cmd> is
# omarchy-pkg-add or omarchy-pkg-aur-add; both are --needed, so a re-run is a
# no-op.
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
