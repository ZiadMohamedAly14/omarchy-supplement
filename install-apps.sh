#!/bin/bash
# Software installed through Omarchy's own installers.
#
# These do more than `pacman -S` — they wire up themes, defaults, secrets and
# services. Always prefer one of these over a raw package install.
#
# See everything available:  omarchy install
# See what a command does:   omarchy install dev-env --help
#
# Subcommands are SPACE-separated, not hyphenated: `editor vscode`, not
# `editor-vscode`. Entries are word-split below, so multi-word args work.
set -euo pipefail

# Each entry is passed verbatim to `omarchy install`.
APPS=(
  "terminal alacritty"   # not in base; also sets the default + SUPER+Return
  "editor vscode"        # + Omarchy theme, secret storage, auto-update off
  "dev-env node"         # via mise; brings npm/npx
  "docker dbs MongoDB"   # see the note below before changing this
  "browser brave-origin" # AUR brave-origin-bin + Omarchy's flags, policy dir,
                         # theme hook and bundled extensions (copy-url, yt-dlp).
                         # Does NOT set the default — see below.

  # "dev-env bun"
  # "dev-env java"       # only for native React Native / Android builds
  # "docker dbs Redis"
  # "service tailscale"  # reach a dev server from a phone off-LAN
  # "service 1password"
)

# On "docker dbs": the installer is menu-driven when called with no arguments,
# but takes them verbatim otherwise (choices="$@"), so naming the database keeps
# the bootstrap unattended. The name is CASE-SENSITIVE — it is matched by a
# `case` statement against: MySQL PostgreSQL Redis MongoDB MariaDB MSSQL.
#
# It is also NOT idempotent on its own: it is a bare `docker run --name <fixed>`,
# so a second run fails with "name already in use". docker_db_exists() below
# checks for the container first — names copied from the installer's `case`.
#
# MongoDB lands on 127.0.0.1:27017 as root admin/admin123:
#   mongodb://admin:admin123@127.0.0.1:27017/?authSource=admin

# docker_db_exists <Name> — true when the container `omarchy install docker dbs
# <Name>` would create is already there (running or not).
docker_db_exists() {
  local container
  case $1 in
  MySQL) container=mysql8 ;;
  PostgreSQL) container=postgres18 ;;
  MariaDB) container=mariadb11 ;;
  Redis) container=redis ;;
  MongoDB) container=mongodb ;;
  MSSQL) container=mssql ;;
  *) return 1 ;; # unknown name — let the installer complain
  esac
  # The installer itself uses `sudo docker`, so sudo here adds no new prompt.
  sudo docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$container"
}

if ((${#APPS[@]} == 0)); then
  echo "No Omarchy apps configured."
else
  for app in "${APPS[@]}"; do
    # shellcheck disable=SC2206
    words=($app)
    if [[ ${words[0]} == docker && ${words[1]-} == dbs ]] && docker_db_exists "${words[2]-}"; then
      echo "──  omarchy install $app — container already exists, skipping"
      continue
    fi

    echo "──  omarchy install $app"
    # shellcheck disable=SC2086
    omarchy install $app || echo "warning: 'omarchy install $app' failed" >&2
  done
fi

# --- font -------------------------------------------------------------------
# Select the system monospace font (install-packages.sh installs the package).
# omarchy-font-set writes ~/.config/fontconfig/fonts.conf — the source of truth
# the shell, Qt and everything resolving "monospace" read — and `sed -i`s the
# font family into any terminal configs it finds.
#
# ORDER MATTERS: that sed does not follow symlinks, so run against a stowed
# ~/.config/alacritty/alacritty.toml it silently replaces the link with a plain
# file and the dotfiles stop tracking it. Here it runs BEFORE install-dotfiles.sh,
# so it only ever edits Omarchy's stock alacritty.toml, which stow then backs up
# and replaces with the dotfiles copy (which already names this font). Never
# run `omarchy font set` / Setup > Font after the dotfiles are in — edit the
# dotfiles instead.
#
# The same hazard applies to a RE-RUN: by then alacritty.toml is the symlink, so
# this must not fire again. fonts.conf naming the font is the "already done"
# signal — it is the file omarchy-font-set writes, and nothing else touches it.
#
# Not `omarchy install font`: that one wraps the same steps in a floating GUI
# terminal, which an unattended script cannot drive.
FONT="CaskaydiaMono Nerd Font"
FONTCONF="$HOME/.config/fontconfig/fonts.conf"
if grep -Fq -- "<string>$FONT</string>" "$FONTCONF" 2>/dev/null; then
  echo "font already set to '$FONT'"
elif fc-list | grep -Fqi -- "$FONT"; then
  omarchy-font-set "$FONT" || echo "warning: could not set the system font" >&2
else
  echo "warning: '$FONT' not installed — is ttf-cascadia-mono-nerd in install-packages.sh?" >&2
fi

# --- defaults -------------------------------------------------------------
# `omarchy install terminal alacritty` already sets the terminal default, so
# there is no `omarchy default terminal` line here. The browser installer does
# NOT — it prints "make it the default via Setup > Defaults > Browser" — hence
# the explicit line below.
#
# Note: remove-preinstalls.sh drops the TUI menu entries (Docker, Disk Usage)
# and they are deliberately not restored. install-packages.sh still reinstalls
# lazydocker, so the binary is there — it just isn't in `omarchy menu`.
# `omarchy default editor` does not touch xdg-settings — it just writes the
# name to ~/.local/state/omarchy/defaults/editor for omarchy-launch-editor to
# read, and it does not check that `code` exists. So it cannot fail on a missing
# install; the guard is only there so an unexpected error cannot abort the run
# under `set -e` before the dotfiles are stowed.
omarchy default editor code || echo "warning: could not set the default editor" >&2

# Only after Brave Origin is actually installed: `omarchy default browser` is a
# bare `xdg-settings set`, which happily points at a desktop file that does not
# exist — and the chromium removal below must never leave the box browserless.
if omarchy-pkg-present brave-origin-bin; then
  omarchy default browser brave-origin ||
    echo "warning: could not set the default browser" >&2

  # Drop Omarchy's stock Chromium now that Brave Origin has replaced it. It IS
  # in omarchy-base.packages, but nothing reinstalls base on `omarchy update`,
  # so it stays gone. There is no `omarchy remove browser chromium`;
  # omarchy-pkg-drop is a no-op when the package is already absent, so this is
  # idempotent. Web apps keep working: omarchy-launch-webapp uses whichever
  # Chromium-family browser is the XDG default, and `brave*` matches.
  omarchy-pkg-drop chromium ||
    echo "warning: could not remove chromium" >&2
else
  echo "warning: brave-origin-bin not installed — keeping chromium as the browser" >&2
fi
