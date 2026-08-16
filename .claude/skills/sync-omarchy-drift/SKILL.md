---
name: sync-omarchy-drift
description: Reconcile the dotfiles and bootstrap against Omarchy after an update — new default keybindings that collide, config files reverted by omarchy refresh, packages newly added to base, changed override files. Use after `omarchy update`, when keybinds start misbehaving, or when a tracked config mysteriously reverts.
---

# Sync with Omarchy after an update

The dotfiles are a **patch against a moving target**. Omarchy updates change defaults,
add packages to base, and can write through Stow symlinks. Nothing here fails loudly — it
drifts.

Run after `omarchy update`, or when something starts behaving oddly.

Steps needing the Arch box are marked. If the user is on Windows, ask them to paste output.

## 1. Did a tracked config get reverted? *(machine)*

The sharpest failure. `omarchy refresh <thing>` and `omarchy reinstall configs` do `cp -f`
onto `~/.config/...`. If that path is a Stow symlink, the copy writes **through** it and
replaces your version in the repo with Omarchy's default.

```bash
cd ~/dotfiles && git status && git diff
```

Unexpected changes to `hypr/.config/hypr/*.lua` or `bash/.bashrc` are this. Recover:

```bash
git checkout -- <file>          # discard Omarchy's default, keep yours
```

Before discarding, **read the diff** — if the update genuinely improved the default, merge
rather than revert. Also look for stray `*.bak.<timestamp>` files in `~/.config/hypr/`;
those are Omarchy's backups of your version.

## 2. Duplicate keybindings *(machine)*

Omarchy may have added a default on a key you also bind. Hyprland **stacks** bindings, so
both fire.

```bash
omarchy menu keybindings --print
hyprctl binds | grep -i "<key>"
```

Any key bound twice needs an `hl.unbind()` before your `o.bind()` in
`hypr/.config/hypr/bindings.lua`:

```lua
hl.unbind("SUPER + F")
o.bind("SUPER + F", "File manager", { launch = "nautilus" })
```

Also check the reverse: an `hl.unbind()` for a key Omarchy no longer binds is a silent
no-op — harmless, but worth removing so the file stays honest.

## 3. Config errors *(machine)*

```bash
hyprctl reload && hyprctl configerrors
```

Repeat until clean. A Lua API that changed between versions shows up here.

## 4. New override files

Omarchy may add a sixth user config to `~/.config/hypr/`, which would arrive unmanaged
because the `hypr` package tracks a fixed set.

```bash
ls /usr/share/omarchy/config/hypr/
ls ~/.config/hypr/
```

Anything present in both but not in `~/dotfiles/hypr/.config/hypr/` is untracked. Decide
whether to capture it (`/capture-dotfile`) or leave it as Omarchy's.

`hyprland.lua` is **deliberately untracked** — it's the loader. Don't add it.

## 5. Packages newly absorbed into base

Omarchy adds packages to base over time. Anything in `install-packages.sh` that is now
shipped is redundant.

```bash
for p in $(grep -oP '^\s*\K[a-z0-9._-]+' ~/omarchy-supplement/install-packages.sh); do
  grep -qx "$p" /usr/share/omarchy/install/omarchy-base.packages && echo "now in base: $p"
done
```

Remove any hits from `PACKAGES`.

Also worth checking: did Omarchy add an official installer for something you install
raw? `omarchy install` — if `foo` now has one, move it from `PACKAGES` to `APPS`, since
the installer also handles theming and defaults.

## 6. Shell defaults

```bash
ls /usr/share/omarchy/default/bash/
```

If Omarchy now ships an alias or function your `.bashrc` also defines, yours wins (it
loads after) — but the duplicate is dead weight and may diverge. Remove yours and take the
default unless you deliberately want the override.

## 7. Read the changelog

```bash
omarchy --version
ls /usr/share/omarchy/migrations/ | tail -20
```

Migrations are the clearest signal of what structurally changed in the release.

## Report

Summarise as: **reverted files** (and whether you restored or merged), **binding
collisions fixed**, **packages dropped as redundant**, **new untracked config**. Then
commit the dotfiles repo — drift fixes are easy to lose.
