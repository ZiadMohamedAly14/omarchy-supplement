#!/bin/bash
# Omarchy plugins.
#
# Omarchy 4 ships its own plugin system, and an authoritative skill describing
# it lives on the machine:
#
#   /usr/share/omarchy/default/agents/skills/omarchy/plugins.md
#
# READ THAT before changing anything here — it versions with the system and
# overrides anything written in this repo.
#
# Plugins are added by git URL, not by name:
#   omarchy plugin add <url> --enable
#
# THIS SCRIPT IS INTERACTIVE, and deliberately runs LAST in install-all.sh.
# `plugin add` prompts — for confirmations, and for plugin configuration such as
# a Todoist API token or a prayer-times location. Those are not questions a
# bootstrap can answer for you, so this step is not automated away; it is simply
# ordered after everything that can complete unattended.
#
# Do NOT wrap these in `yes |` the way remove-preinstalls.sh does. That works
# for a pacman [Y/n], but blindly answering "y" to a credential prompt just
# stores garbage. If `omarchy plugin add --help` reveals a real non-interactive
# flag, use that instead — check before assuming there isn't one.
#
# These run code from third-party repos inside your session, so they carry the
# same trust as any other software you install from GitHub. Pin or fork if that
# matters to you — `plugin add` tracks the upstream default branch.
#
# Skip entirely with OMARCHY_SKIP_PLUGINS=1 ./install-all.sh
set -euo pipefail

if [[ ${OMARCHY_SKIP_PLUGINS:-0} == 1 ]]; then
  echo "OMARCHY_SKIP_PLUGINS=1 — skipping plugin install"
  exit 0
fi

PLUGINS=(
  "https://github.com/husamemadH/omarchy-quattro-prayer-times.git"
  "https://github.com/Aryan-Techie/omarchy-todoist.git"

  # Needs Steam. install-apps.sh runs before this script, so uncommenting
  # "gaming steam" there is enough to satisfy it — but Steam plus its graphics
  # drivers is a large install, so it is opt-in rather than implied.
  "https://github.com/silvaio/gamemode-switcher.git"
)

if ((${#PLUGINS[@]} == 0)); then
  echo "No Omarchy plugins configured."
  exit 0
fi

for url in "${PLUGINS[@]}"; do
  name=${url##*/}
  name=${name%.git}

  echo "──  omarchy plugin add $name"
  # Re-adding an existing plugin is expected to fail on a second run; that must
  # not abort the bootstrap.
  omarchy plugin add "$url" --enable ||
    echo "warning: plugin '$name' failed (already added?)" >&2
done
