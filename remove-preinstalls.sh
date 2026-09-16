#!/bin/bash
# Strip Omarchy's preinstalled app set — web apps, TUIs, and selected packages.
#
# Runs BEFORE install-packages.sh so the handful worth keeping can be put back
# there. The removal is all-or-nothing; Omarchy offers no per-app variant.
#
# IMPORTANT: this removes packages that ARE in omarchy-base.packages —
# `lazydocker` among them. So once this script is in the run, "it's in base"
# stops being a reason to leave something out of install-packages.sh. Check
# against what this actually removed, not against the base list.
#
# Reverse the whole thing with:  omarchy install preinstalls
set -euo pipefail

# Escape hatch: OMARCHY_KEEP_PREINSTALLS=1 ./install-all.sh
if [[ ${OMARCHY_KEEP_PREINSTALLS:-0} == 1 ]]; then
  echo "OMARCHY_KEEP_PREINSTALLS=1 — keeping Omarchy's preinstalled apps"
  exit 0
fi

# Omarchy records that the removal happened, and its inverse (`omarchy install
# preinstalls`) deletes the marker again. Honour it: without this guard every
# re-run strips omacalc/omacut/omawrite/lazydocker/WhatsApp and reloads Hyprland,
# only for install-packages.sh and install-webapps.sh to put them straight back
# — two opposing pacman transactions for zero net change.
MARKER="$HOME/.local/state/omarchy/preinstalls-removed"
if [[ -e $MARKER ]]; then
  echo "preinstalls already removed (${MARKER#"$HOME"/} exists) — nothing to do"
  exit 0
fi

# The sudo timestamp is primed and kept alive by install-all.sh.

# `omarchy remove preinstalls` opens with `gum confirm "Are you sure…"` (not a
# pacman [Y/n] — its package removals go through omarchy-pkg-drop, which is
# already --noconfirm). An unattended bootstrap must not block on it, so `yes`
# pre-answers. There is no --yes flag on this command; check again after an
# update in case one appears:
#   grep -nE 'ASSUME_YES|--yes' /usr/bin/omarchy-remove-preinstalls
#
# Two subtleties, both of which look like bugs if you hit them cold:
#
#   1. `yes` is killed by SIGPIPE the moment the consumer exits, so the
#      pipeline's own exit status describes `yes`, not the removal. The real
#      status is PIPESTATUS[1].
#   2. `set -e` is lifted across the pipeline, and a non-zero exit here must not
#      abort install-all.sh — it treats a failed child as fatal.
#
# `yes` blanket-approves EVERY prompt, not just that one. If a future Omarchy
# version adds another confirmation here, this answers that too.
set +e
yes | omarchy remove preinstalls
rc=${PIPESTATUS[1]}
set -e

((rc == 0)) ||
  echo "warning: 'omarchy remove preinstalls' exited $rc (already removed?)" >&2
