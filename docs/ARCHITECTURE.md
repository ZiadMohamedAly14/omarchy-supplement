# Architecture

How `omarchy-supplement` and `dotfiles` take a stock Omarchy 4 install to a finished
machine.

## Three layers

```
┌──────────────────────────────────────────────────────────────────┐
│  Layer 3 — dotfiles              declarative · GNU Stow          │
│  ~/dotfiles/{bash,hypr}  →  symlinks into $HOME                  │
├──────────────────────────────────────────────────────────────────┤
│  Layer 2 — omarchy-supplement    imperative · bash               │
│  omarchy-pkg-add · omarchy install · stow                        │
├──────────────────────────────────────────────────────────────────┤
│  Layer 1 — Omarchy 4             upstream, /usr/share/omarchy    │
│  Hyprland(Lua) · Quickshell bar · bash defaults · mise · nvim    │
│  424 `omarchy-*` commands · agent skills · hooks · migrations    │
└──────────────────────────────────────────────────────────────────┘
```

Layer 2 is the only layer that acts. Layer 3 is inert data it deploys. Layer 1 is
upstream, owned by a pacman package, and is **overlaid, never edited**.

**Why two repos?** Different change cadence and different failure modes. Dotfiles change
constantly and a bad change is instantly visible. Install scripts change rarely and a bad
change is invisible until the next fresh install, months later. Splitting them keeps
dotfiles history readable as a config log and keeps the install path small enough to audit
by eye.

## Bootstrap sequence

```
1. Install Omarchy 4                              (upstream installer)
2. git clone .../omarchy-supplement ~/omarchy-supplement
3. cd ~/omarchy-supplement && ./install-all.sh
     ├─ install-stow.sh       stow, if missing        ← must precede dotfiles
     ├─ install-packages.sh   omarchy-pkg-add / omarchy-pkg-aur-add
     ├─ install-apps.sh       omarchy install <...>; omarchy default <...>
     └─ install-dotfiles.sh   ① clone → ~/dotfiles
                              ② back up conflicts → ~/.dotfiles-backup-<ts>/
                              ③ stow bash hypr
4. Log out and back in
```

Children are **executed** (`bash ./x.sh`), not sourced, so a child's `exit` or `set -e`
cannot corrupt the parent run.

The only hard ordering constraint is **stow before dotfiles**. Packages and apps are
independent.

## How overrides work in Omarchy 4

This is the part that changed most from Omarchy 3, and it is much simpler now.

### Hyprland — designated user files

Omarchy ships `~/.config/hypr/hyprland.lua` as a loader that does, in order:

```lua
dofile(OMARCHY_PATH .. "/default/hypr/bootstrap.lua")
require("default.hypr.omarchy")   -- Omarchy's defaults
require("hypr.monitors")          -- ← yours, loaded after, so yours win
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
require("default.hypr.toggles")
```

Those five user files are exactly what the `hypr` Stow package provides. **No config
patching, no appended source lines** — Omarchy designed the extension point, we just fill
it.

`hyprland.lua` itself is *not* stowed. It is the loader and Omarchy may change it between
versions; pinning a stale copy would break the boot path. The cost is that if Omarchy adds
a sixth override file, it appears unmanaged until we add it to the package — a cheap
trade.

Because bindings **stack** rather than replace, every rebind must be paired:

```lua
hl.unbind("SUPER + F")
o.bind("SUPER + F", "File manager", { launch = "nautilus" })
```

### Shell — a documented append point

`~/.bashrc` is explicitly yours and never overwritten by updates. It sources
`$OMARCHY_PATH/default/bash/rc` for Omarchy's aliases and functions; personal config goes
below that. The `bash` Stow package tracks the whole file, bootstrap block included, so
the ordering is version-controlled.

### Everything else

`~/.config/omarchy/shell.json` (bar, widgets, idle), `extensions/omarchy-menu.jsonc` (menu
entries), and `hooks/<event>.d/` (post-boot, post-update, theme-set, font-set,
battery-low, pre-refresh-pacman) are all plain files in `~/.config`. Add them as Stow
packages when needed — nothing special is required.

## Use Omarchy's CLI before writing anything

424 commands. The ones that replace work this repo would otherwise do:

| Need | Command |
|---|---|
| Install repo packages | `omarchy-pkg-add` — wraps `pacman -S --noconfirm --needed`, then verifies |
| Install AUR packages | `omarchy-pkg-aur-add` — wraps `yay` |
| Language runtime | `omarchy install dev-env <ruby\|node\|go\|python\|rust\|…>` — 18, via mise |
| VS Code | `omarchy install editor-vscode` — package, theme, secrets, auto-update off |
| Databases | `omarchy install docker-dbs` |
| Set defaults | `omarchy default editor\|terminal\|browser` |
| Reset a config | `omarchy refresh <thing>` (backs your version up first) |

**Prefer an Omarchy installer over a raw package install** — they configure as well as
install, and stay correct across updates.

### Already in base — never install

`tmux` `mise` `starship` `fzf` `zoxide` `lazygit` `git` `jq` `nvim` `alacritty` `foot` `yay`

Verify: `grep -x <pkg> /usr/share/omarchy/install/omarchy-base.packages`

## Stow mechanics

```
~/dotfiles/bash/.bashrc  →  ~/.bashrc
          └──┘└────────┘
        package  $HOME-relative
```

Targets resolve relative to the package's parent, so the clone must be at `~/dotfiles`.
Deployed paths are symlinks into the repo — editing the live file edits the repo file, and
there is no copy-back step.

`install-dotfiles.sh` moves any conflicting real file to `~/.dotfiles-backup-<timestamp>/`
before linking. Nothing is deleted, so the script is safe on a machine already in use —
not just a fresh one.

## Runtime layout

| Path | Owner | Purpose |
|---|---|---|
| `~/omarchy-supplement/` | this repo | Install scripts. Nothing reads it after bootstrap. |
| `~/dotfiles/` | dotfiles repo | Stow packages; symlink targets |
| `/usr/share/omarchy/` | pacman | Omarchy itself — `$OMARCHY_PATH`. Never edit. |
| `~/.config/hypr/*.lua` | us, via Stow | Hyprland overrides |
| `~/.bashrc` | us, via Stow | Shell |
| `~/.dotfiles-backup-<ts>/` | install-dotfiles.sh | Whatever Stow displaced |

Unlike Omarchy 3 setups, **nothing is read from the supplement clone at runtime.** It is a
true one-shot installer and can be deleted after use (though keeping it makes re-running
easy).

## Design decisions

**Scripts are flat, single-purpose, and executed not sourced.** No shared `lib/`. Each is
independently runnable on a machine in any state. The price is a little duplication;
the benefit is that nothing depends on load order.

**Lists over scripts.** `install-packages.sh` and `install-apps.sh` are arrays with
commented examples rather than a script per tool. Adding software is a one-line edit, and
there is no per-tool boilerplate to keep idempotent.

**Non-destructive by default.** Conflicts are moved, never deleted. This is what makes the
bootstrap safe to re-run on a working machine.

**Thin supplement, fat dotfiles.** In Omarchy 4, customisation is files in `~/.config`.
Resist adding logic here that could instead be a config file there.
