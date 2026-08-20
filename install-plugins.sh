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
# These run code from third-party repos inside your session, so they carry the
# same trust as any other software you install from GitHub. Pin or fork if that
# matters to you — `plugin add` tracks the upstream default branch.
set -euo pipefail

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
