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
  "browser chrome"       # React/Next devtools
  "docker dbs MongoDB"   # see the note below before changing this

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
# It is also NOT idempotent: the container name is fixed, so a second run fails
# with "name already in use". The `|| echo warning` below absorbs that.
#
# MongoDB lands on 127.0.0.1:27017 as root admin/admin123:
#   mongodb://admin:admin123@127.0.0.1:27017/?authSource=admin

if ((${#APPS[@]} == 0)); then
  echo "No Omarchy apps configured."
  exit 0
fi

for app in "${APPS[@]}"; do
  echo "──  omarchy install $app"
  # shellcheck disable=SC2086
  omarchy install $app || echo "warning: 'omarchy install $app' failed" >&2
done

# Set defaults once the apps exist. Uncomment what applies.
# `omarchy install terminal alacritty` already sets the terminal default, so
# there is no `omarchy default terminal` line here.
omarchy default editor code
# omarchy default browser chrome
