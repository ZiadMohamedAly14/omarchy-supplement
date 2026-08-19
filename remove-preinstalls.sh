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

# Prime the sudo timestamp so the password prompt happens here, once, instead of
# surfacing partway through a later script.
sudo -v

# Pacman asks ":: Do you want to remove these packages? [Y/n]" and an unattended
# bootstrap must not block on it, so `yes` pre-answers.
#
# Two subtleties, both of which look like bugs if you hit them cold:
#
#   1. `yes` is killed by SIGPIPE the moment the consumer exits, so the
#      pipeline's own exit status describes `yes`, not the removal. The real
#      status is PIPESTATUS[1].
#   2. `set -e` is lifted across the pipeline. A second run has nothing left to
#      remove and may exit non-zero; install-all.sh treats a failed child as
#      fatal, so that would break idempotency.
#
# `yes` blanket-approves EVERY prompt, not just the pacman one. If a future
# Omarchy version adds its own confirmation here, this answers that too. Prefer
# a real non-interactive flag if one ever appears:
#   grep -nE 'noconfirm|--yes' /usr/share/omarchy/bin/omarchy-remove-preinstalls
set +e
yes | omarchy remove preinstalls
rc=${PIPESTATUS[1]}
set -e

((rc == 0)) ||
  echo "warning: 'omarchy remove preinstalls' exited $rc (already removed?)" >&2
