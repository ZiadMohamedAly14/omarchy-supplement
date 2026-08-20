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

# `webapp` is a TOP-LEVEL command group, not a subcommand of `omarchy install`.
# The backing script is /usr/bin/omarchy-webapp-install, which maps to this by
# Omarchy's naming convention (omarchy-install-editor-vscode -> "install editor
# vscode"). Confirm the argument order with:
#   omarchy webapp
#   head -30 /usr/bin/omarchy-webapp-install
WEBAPP_CMD=(omarchy webapp install)

# "Display Name|URL" — split on | so display names may contain spaces.
# The installer takes exactly these two arguments; it sources the icon itself.
#
# URLs are copied verbatim from Omarchy's own definitions in
# /usr/share/omarchy/applications/{Discord,WhatsApp}.desktop. Note Discord's is
# /channels/@me, not /app.
#
# Caveat on icons: those same desktop files use curated icon-theme names
# (Icon=omarchy-discord, Icon=whatsapp) which a two-argument install cannot
# reproduce, so the launcher icons may differ from stock Omarchy. If that
# bothers you, copy Omarchy's entries instead of installing them:
#   cp /usr/share/omarchy/applications/{Discord,WhatsApp}.desktop \
#      ~/.local/share/applications/
WEBAPPS=(
  "Discord|https://discord.com/channels/@me"
  "WhatsApp|https://web.whatsapp.com/"
)

if ((${#WEBAPPS[@]} == 0)); then
  echo "No web apps configured."
  exit 0
fi

APPDIR="$HOME/.local/share/applications"
mkdir -p "$APPDIR"

for entry in "${WEBAPPS[@]}"; do
  IFS='|' read -r name url <<<"$entry"
  template="/usr/share/omarchy/applications/${name}.desktop"

  # Prefer Omarchy's own entry when it ships one. `omarchy webapp install` takes
  # only a name and a URL and sources the icon from the site's favicon — which
  # WhatsApp does not serve, so it lands with no icon at all. Omarchy's shipped
  # entries hardcode curated icon-theme names (Icon=whatsapp, Icon=omarchy-discord)
  # and are exactly what `remove preinstalls` deleted from $APPDIR in the first
  # place. Copying them back is both correct and unguessable-free.
  if [[ -r $template ]]; then
    cp -f "$template" "$APPDIR/"

    # `omarchy webapp install` sources icons from the site's favicon and writes
    # them to ~/.local/share/icons. When a site serves nothing usable — WhatsApp
    # is the known case — it leaves a broken file there, and because
    # ~/.local/share/icons OUTRANKS /usr/share/icons in XDG lookup, that broken
    # file shadows the good icon Omarchy ships. The desktop entry looks correct
    # and the app still has no icon.
    #
    # Move any such shadow aside (never delete — same rule as the dotfiles
    # backup) but only when Omarchy actually provides a system icon to fall
    # back to.
    icon=$(awk -F= '/^Icon=/{print $2; exit}' "$template")
    if [[ -n $icon ]] && compgen -G "/usr/share/icons/hicolor/*/apps/$icon.png" >/dev/null; then
      while IFS= read -r shadow; do
        mv -f "$shadow" "$shadow.bak"
        echo "  moved shadowing icon aside: ${shadow#"$HOME"/} -> ….bak"
      done < <(compgen -G "$HOME/.local/share/icons/hicolor/*/apps/$icon.png" || true)
    fi

    echo "✓ $name — restored Omarchy's own entry (icon included)"
    continue
  fi

  # No shipped entry: a web app of your own. Generate one.
  echo "──  ${WEBAPP_CMD[*]} $name"
  # Re-adding an existing web app is expected to fail on a second run; that must
  # not abort the bootstrap.
  "${WEBAPP_CMD[@]}" "$name" "$url" ||
    echo "warning: web app '$name' failed (already installed?)" >&2
done

# Refresh the desktop and icon caches so launchers pick the changes up without
# a relogin. Both are best-effort; neither failing matters.
command -v update-desktop-database &>/dev/null &&
  update-desktop-database "$APPDIR" 2>/dev/null || true

command -v gtk-update-icon-cache &>/dev/null &&
  gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
