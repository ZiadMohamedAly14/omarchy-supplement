# omarchy-supplement

Post-install bootstrap for a fresh [Omarchy 4](https://omarchy.org) machine.

Omarchy gives you a complete desktop. This adds the handful of things it doesn't ship and
links my config files into place. Pairs with
**[dotfiles](https://github.com/ZiadMohamedAly14/dotfiles)** — this repo *does* things, that
repo *is* things.

## Install

```bash
git clone https://github.com/ZiadMohamedAly14/omarchy-supplement.git ~/omarchy-supplement
cd ~/omarchy-supplement
./install-all.sh
```

Then log out and back in.

Safe to re-run. Nothing is deleted — any config Omarchy already placed is moved to
`~/.dotfiles-backup-<timestamp>/` before being replaced with a symlink.

## What it does

| Script | |
|---|---|
| `install-stow.sh` | GNU Stow — the one thing needed before anything else |
| `install-packages.sh` | Extra Arch packages, via `omarchy-pkg-add` / `omarchy-pkg-aur-add` |
| `install-apps.sh` | Omarchy's own installers — VS Code, dev environments, services |
| `install-dotfiles.sh` | Clones `~/dotfiles` and stows it into `$HOME` |

`install-all.sh` runs all four in order.

## Making it yours

This is a starter. The package and app lists ship nearly empty — fill them in.

**Add an Arch package** → `PACKAGES` in [install-packages.sh](install-packages.sh).
Check it isn't already in base first:

```bash
grep -x ripgrep /usr/share/omarchy/install/omarchy-base.packages
```

**Add software Omarchy can install properly** → `APPS` in [install-apps.sh](install-apps.sh).
These do more than a package install — themes, secrets, defaults:

```bash
omarchy install            # see everything available
```

```bash
APPS=(
  "editor-vscode"
  "dev-env node"
)
```

**Add a config file** → create the Stow package in the dotfiles repo, then add its name to
`PACKAGES` in [install-dotfiles.sh](install-dotfiles.sh). Both halves, or it won't deploy.

## Notes

- Omarchy 4 configures Hyprland in **Lua**. Your overrides live in
  `~/.config/hypr/{bindings,monitors,input,looknfeel,autostart}.lua`, stowed from the
  dotfiles repo. Validate changes with `hyprctl reload && hyprctl configerrors`.
- The shell is **bash**. Personal config goes in `~/.bashrc` below Omarchy's bootstrap
  block.
- Before writing any install script, check whether `omarchy` already does it —
  there are 424 commands.

## Docs

- [CLAUDE.md](CLAUDE.md) — Omarchy 4 facts, invariants, working rules
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the two repos combine
- [docs/CONVENTIONS.md](docs/CONVENTIONS.md) — rules for writing scripts here
