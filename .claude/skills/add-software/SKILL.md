---
name: add-software
description: Add a package, app, language runtime, or service to the Omarchy bootstrap — picking the right mechanism (package list, omarchy installer, or a new script). Use whenever the user wants something installed on fresh setups: "add docker", "I want yazi", "install node", "make VS Code the default editor".
---

# Add software to the bootstrap

In Omarchy 4 most additions are **a one-line list edit, not a new script.** Work down this
order and stop at the first that fits.

## 1. Does Omarchy already ship it?

```bash
grep -x <package> /usr/share/omarchy/install/omarchy-base.packages
```

Already in base — never install these:
`tmux` `mise` `starship` `fzf` `zoxide` `lazygit` `git` `jq` `nvim` `alacritty` `foot` `yay`

If it's shipped, the task is **configuration**, not installation → `/capture-dotfile`.

## 2. Does Omarchy have an installer for it?

```bash
omarchy install          # list all
omarchy                  # all 424 commands
```

Omarchy's installers do more than `pacman -S` — themes, secrets, service setup, defaults.
**Always prefer one over a raw package install.**

Add to `APPS` in `install-apps.sh`:

```bash
APPS=(
  "editor-vscode"      # package + Omarchy theme + secrets + auto-update off
  "dev-env node"       # via mise
  "docker-dbs"
)
```

Covers: `dev-env` (18 languages), `editor-*`, `browser`, `terminal`, `gaming-*`,
`service-*`, `docker-dbs`, `font`, `app`.

**Language runtimes always go here.** Omarchy uses mise; never hand-roll a version manager
or add asdf.

## 3. Plain Arch package?

Add to `install-packages.sh` — `PACKAGES` for official repos, `AUR_PACKAGES` for AUR
(slower, builds from source):

```bash
PACKAGES=(
  yazi
  postgresql
)
```

Find the name with `pacman -Ss <tool>` or `yay -Ss <tool>` on the machine. If the user is
on Windows and can't check, say plainly that the name is unverified.

## 4. Default application?

No script needed — uncomment in `install-apps.sh`:

```bash
omarchy default editor code
omarchy default terminal alacritty
omarchy default browser chromium
```

## 5. Only now, a new script

Justified only for multi-step system state changes with no Omarchy equivalent — a systemd
service, a cluster to initialise, a repo to clone and build.

```bash
#!/bin/bash
set -euo pipefail

command -v foo &>/dev/null || { echo "foo required; run ./install-foo.sh first" >&2; exit 1; }

omarchy-pkg-add bar

TARGET="$HOME/.local/share/foo"
if [[ -d $TARGET ]]; then
  echo "foo already set up"
else
  git clone https://github.com/example/foo "$TARGET"
fi
```

Rules: `omarchy-pkg-add` not `pacman`/`yay` · guard every non-package action · no prompts ·
never `rm -rf` in `$HOME` (move to a timestamped backup) · `chmod +x` · add a `run` line to
`install-all.sh` only if every machine needs it.

Full rules: [docs/CONVENTIONS.md](../../../docs/CONVENTIONS.md).

## Verify

You cannot run any of this — development is Windows, target is Arch.

- `bash -n install-<tool>.sh`
- `shellcheck` if available
- Re-read asking *what happens on the second run?*

Tell the user what to run on the machine, and that running it twice should be a no-op the
second time.

## Then update

`CLAUDE.md` and `README.md` if the bootstrap's shape changed. A list entry usually needs no
doc change.
