#!/bin/bash
# Omarchy plugins, plus the shell.json they slot into.
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
#   omarchy plugin add <url> --enable --yes
#
# `--yes` is what makes this unattended. Without it, `plugin add` refuses to run
# at all when stdin is not a terminal ("refusing to continue without
# confirmation; pass --yes"), and with a terminal it stops on a gum confirm. It
# also skips the "which bar section?" prompt and falls back to the manifest's
# defaultSection — moot here, because the seeded shell.json below already has
# every widget placed.
#
# This script still runs LAST in install-all.sh. Some plugins ask for their own
# configuration on first launch (a Todoist API token, a prayer-times location);
# those prompts belong to the plugin, not to `plugin add`, and a bootstrap
# cannot answer them for you.
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

# --- shell.json -------------------------------------------------------------
# Bar layout (which widget in which section, clock format), idle timeouts. This
# is deliberately a COPY, not a stow package: Omarchy rewrites the file through
# `mktemp` + `mv` (see /usr/bin/omarchy-shell-config), which would replace a
# symlink with a plain file the first time a plugin is enabled or the bar is
# edited — the same trap omarchy-font-set springs on alacritty.toml.
#
# Seeded only when absent, so a machine that has been tweaked since keeps its
# tweaks. After changing the bar, re-capture with:
#   cp ~/.config/omarchy/shell.json config/omarchy/shell.json
#
# Runs BEFORE the plugins so they are enabled into this layout rather than
# appended to Omarchy's default one.
SHELL_JSON="$HOME/.config/omarchy/shell.json"
SEED="$(dirname "${BASH_SOURCE[0]}")/config/omarchy/shell.json"

if [[ ! -e $SHELL_JSON ]]; then
  mkdir -p "$(dirname "$SHELL_JSON")"
  cp "$SEED" "$SHELL_JSON"
  echo "✓ seeded ${SHELL_JSON#"$HOME"/}"
elif cmp -s "$SEED" "$SHELL_JSON"; then
  echo "shell.json matches the repo copy"
else
  echo "shell.json exists and differs — leaving it alone (repo copy: config/omarchy/shell.json)"
fi

# --- plugins ----------------------------------------------------------------
# "git-url|plugin-id". The id is the `id` field of the plugin's manifest.json —
# it is what `omarchy plugin list` prints and what the guard below matches on.
# It cannot be derived from the URL, so it is spelled out. To find one:
#   git clone <url> /tmp/p && jq -r .id /tmp/p/manifest.json
PLUGINS=(
  "https://github.com/husamemadH/omarchy-quattro-prayer-times.git|local.prayer-times"
  "https://github.com/Aryan-Techie/omarchy-todoist.git|io.github.aryan-techie.todoist"
  "https://github.com/jankeesvw/omarchy-notification-center.git|jankeesvw.notification-center"

  # Needs Steam. install-apps.sh runs before this script, so uncommenting
  # "gaming steam" there is enough to satisfy it — but Steam plus its graphics
  # drivers is a large install, so it is opt-in rather than implied.
  # "https://github.com/silvaio/gamemode-switcher.git|<id>"
)

if ((${#PLUGINS[@]} == 0)); then
  echo "No Omarchy plugins configured."
  exit 0
fi

# `plugin add` refuses an id that is already installed ("plugin id '…' is
# already used by …"), so check first rather than absorb the failure.
installed=$(omarchy plugin list 2>/dev/null | awk 'NR > 1 { print $1 }')

for entry in "${PLUGINS[@]}"; do
  IFS='|' read -r url id <<<"$entry"

  if grep -qx -- "$id" <<<"$installed"; then
    echo "──  $id already installed"
    continue
  fi

  echo "──  omarchy plugin add $id"
  omarchy plugin add "$url" --enable --yes ||
    echo "warning: plugin '$id' failed to install" >&2
done
