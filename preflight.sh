#!/bin/bash
# Bring the package databases up to date before anything tries to install.
#
# A fresh Omarchy install can land with no pacman sync databases at all. Every
# install in this bootstrap then fails like this:
#
#   warning: database file for 'core' does not exist (use '-Sy' to download)
#   error: target not found: stow
#
# `omarchy-pkg-add` does NOT refresh them — it calls `pacman -S` directly, which
# cannot resolve a package it has no index for. So this runs first, before
# remove-preinstalls.sh and every install-*.sh.
set -euo pipefail

# Prime the sudo timestamp so the password prompt happens here, once, rather
# than surfacing partway through a long AUR build.
sudo -v

# Set OMARCHY_SKIP_SYNC=1 to skip — useful on a back-to-back re-run.
if [[ ${OMARCHY_SKIP_SYNC:-0} == 1 ]]; then
  echo "OMARCHY_SKIP_SYNC=1 — leaving package databases alone"
  exit 0
fi

echo "Updating via omarchy..."

# NOT `pacman -Syu`. Omarchy installs a pacman pre-transaction hook that refuses
# a direct system upgrade and points here:
#
#   "This looks like a direct pacman system upgrade. Omarchy updates should
#    normally run through: omarchy update"
#
# That path also takes a snapshot, refreshes keyrings, runs migrations, fires
# post-update hooks, and does the restart check. Bypassing it with
# OMARCHY_ALLOW_DIRECT_PACMAN=1 skips all of that — don't.
#
# But a full update is PREFERRED, not REQUIRED. What the rest of the bootstrap
# actually needs is only that pacman has sync databases; without them every
# install fails with "target not found". `omarchy update` has its own guards and
# will refuse outright on a small disk:
#
#   You need at least 10 GiB free to safely update Omarchy.
#
# Treating that as fatal would block the entire bootstrap over a nice-to-have,
# so fall back to a database-only sync.
if omarchy update; then
  exit 0
fi

echo >&2
echo "warning: 'omarchy update' did not complete." >&2
echo "         Falling back to a database-only sync so the bootstrap can" >&2
echo "         continue. Re-run 'omarchy update' once the cause is resolved" >&2
echo "         (low disk space is the usual one — it wants 10 GiB free)." >&2
echo >&2

# -Sy with no -u: not an upgrade transaction, so Omarchy's pre-transaction hook
# does not fire. This leaves a partial-upgrade window — the databases advertise
# newer versions than the installed libraries, so a package installed now can
# link against something not yet on disk. Accepted deliberately: the alternative
# is a bootstrap that cannot install anything at all.
sudo pacman -Sy
