---
name: capture-dotfile
description: Capture a config file into the dotfiles repo as a GNU Stow package and wire it into install-dotfiles.sh so it deploys on fresh installs. Use when the user wants a config tracked — "save my alacritty config", "keep my keybindings", "I tweaked X, make it survive a reinstall".
---

# Capture a config into dotfiles

Config files live in the **dotfiles** repo. This spans both repos: create the package in
one, add its name to `PACKAGES` in the other. **Doing only the first half is the common
mistake** — a package not in that array never deploys.

Repos: `D:\Repos\my-omarchy-setup\{dotfiles,omarchy-supplement}` (dev) · `~/dotfiles`,
`~/omarchy-supplement` (live).

## 1. Is it already tracked?

```bash
ls ~/dotfiles                                     # existing packages
grep -A6 "^PACKAGES=" ~/omarchy-supplement/install-dotfiles.sh
```

If the live path is already a symlink into `~/dotfiles`, it's tracked — the user just needs
to commit.

## 2. Pick the right target

| Config | Where it goes |
|---|---|
| **Hyprland** — keybinds, monitors, input, look, autostart | The **existing `hypr` package**. Edit `bindings.lua` / `monitors.lua` / `input.lua` / `looknfeel.lua` / `autostart.lua`. Do not create a new package. |
| `~/.config/hypr/hyprland.lua` | **Never track.** It's Omarchy's loader; a stale copy breaks future versions. |
| Shell aliases, exports, functions | The **existing `bash` package** — append below the bootstrap block in `.bashrc`. |
| Anything else in `~/.config` | New package. |

Common next candidates: `~/.config/omarchy/shell.json` (bar, idle),
`~/.config/omarchy/extensions/omarchy-menu.jsonc` (menu entries),
`~/.config/omarchy/hooks/<event>.d/` (post-boot, theme-set, battery-low),
`~/.config/alacritty/`, `~/.XCompose`.

## 3. Create the package

The interior mirrors `$HOME` exactly:

```
~/dotfiles/<package>/<path relative to $HOME>

alacritty → ~/dotfiles/alacritty/.config/alacritty/alacritty.toml → ~/.config/alacritty/alacritty.toml
git       → ~/dotfiles/git/.gitconfig                             → ~/.gitconfig
```

Name it after the tool, lowercase, matching existing style (`bash`, `hypr`).

**Copy the real content from the machine — never invent a config.** If the user is on
Windows and can't reach the file, ask them to paste it.

## 4. Wire it up

In omarchy-supplement's `install-dotfiles.sh`:

```bash
PACKAGES=(
  bash
  hypr
  alacritty     # ← new
)
```

Without this it will never deploy. No other change is needed — the script already backs up
conflicting files automatically.

## 5. Deploy

```bash
cd ~/dotfiles && git pull && stow --restow alacritty
```

Or re-run `~/omarchy-supplement/install-dotfiles.sh`, which handles backup + restow.

On a Stow conflict the target exists as a real file — move it aside, don't `--force`:

```bash
mv ~/.config/alacritty/alacritty.toml{,.bak}
```

## 6. Commit both repos

Two commits. Reference the pairing so the connection is visible later —
`Add alacritty stow package` / `Stow alacritty on install`.

## 7. Update docs

`dotfiles/README.md` and `dotfiles/CLAUDE.md` — add the package to the table.

## Worth telling the user once

Deployed paths are **symlinks into the repo**, so editing the live file edits the repo
file. No copy-back step; just commit from `~/dotfiles`.

One caveat: `omarchy refresh <thing>` and `omarchy reinstall configs` do `cp -f`, which
writes *through* a symlink and replaces the repo's copy with Omarchy's default. Only
explicit commands do this, and `git diff` shows it — recover with `git checkout`.
