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
# A bare `pacman -Sy` would populate the databases without tripping the hook,
# but it leaves a partial-upgrade state: the databases advertise new versions
# while the installed libraries are still old, so a package installed right
# afterwards can link against something that isn't on disk. On a fresh machine
# the repos have already moved on, so that risk is real, not theoretical.
omarchy update
