#!/bin/bash
# Omarchy web apps — a site wrapped in a Chromium app window with its own
# desktop entry, launcher icon and window class.
#
# Cheaper than the native package in every way that matters here: Discord's
# Arch package is an Electron bundle (~100 MB plus a second Chromium at
# runtime), while the web app reuses the Chromium already in base.
#
# Omarchy ships a set of these by default and remove-preinstalls.sh strips them,
# which is why Discord and WhatsApp have to be put back explicitly:
#   Removing web app: Discord
#   Removing web app: WhatsApp
set -euo pipefail

# VERIFY THIS LINE before the first run. `omarchy install` does not list a web
# app entry, so the command lives elsewhere in the router and its exact spelling
# is not guessable — Omarchy's subcommands have surprised us repeatedly
# (`editor vscode`, `docker dbs`, `remove dev env`). Find it with:
#   omarchy | grep -iE 'web|app'
#   ls /usr/share/omarchy/bin/ | grep -iE 'webapp|web-app'
# Everything below is independent of this line.
WEBAPP_CMD=(omarchy install webapp)

# "Display Name|URL|Icon URL" — split on | so display names may contain spaces.
#
# The icon URLs are the part most likely to be wrong. Omarchy's own preinstalled
# definitions are the authoritative source; find the exact name/URL/icon it uses
# with:
#   grep -rn -iE 'discord|whatsapp' /usr/share/omarchy/ | head
WEBAPPS=(
  "Discord|https://discord.com/app|https://omarchy.org/webapps/discord.png"
  "WhatsApp|https://web.whatsapp.com|https://omarchy.org/webapps/whatsapp.png"
)

if ((${#WEBAPPS[@]} == 0)); then
  echo "No web apps configured."
  exit 0
fi

for entry in "${WEBAPPS[@]}"; do
  IFS='|' read -r name url icon <<<"$entry"

  echo "──  ${WEBAPP_CMD[*]} $name"
  # Re-adding an existing web app is expected to fail on a second run; that must
  # not abort the bootstrap.
  "${WEBAPP_CMD[@]}" "$name" "$url" "$icon" ||
    echo "warning: web app '$name' failed (already installed?)" >&2
done
