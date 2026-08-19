#!/bin/bash
# Refresh pacman's sync databases before anything tries to install.
#
# A fresh Omarchy install can land with no sync databases at all. Every install
# in this bootstrap then fails like this:
#
#   warning: database file for 'core' does not exist (use '-Sy' to download)
#   error: target not found: stow
#
# `omarchy-pkg-add` does NOT refresh the databases — it calls `pacman -S`
# directly, which cannot resolve a package it has no index for. So this has to
# happen first, before remove-preinstalls.sh and every install-*.sh.
set -euo pipefail

# Prime the sudo timestamp so the password prompt happens here, once, rather
# than surfacing partway through a long AUR build.
sudo -v

echo "Refreshing package databases..."

# -Syu rather than a bare -Sy. `-Sy` alone leaves a partial-upgrade state: the
# databases advertise new versions while the installed libraries are still old,
# so a package installed straight afterwards can link against something that
# isn't on disk. On a fresh machine the upgrade is small; on a re-run it is
# usually a no-op.
#
# Set OMARCHY_SKIP_SYNC=1 to skip (useful when re-running back to back).
if [[ ${OMARCHY_SKIP_SYNC:-0} == 1 ]]; then
  echo "OMARCHY_SKIP_SYNC=1 — leaving package databases alone"
  exit 0
fi

sudo pacman -Syu --noconfirm
