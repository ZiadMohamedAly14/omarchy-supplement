---
name: verify-bootstrap
description: Statically audit the fresh-install path across omarchy-supplement and dotfiles — idempotency, ordering, stow wiring, Omarchy 4 correctness — before pushing changes that can only be tested by wiping a machine. Use before a push, after editing install scripts, or when asked "will this work on a fresh install".
---

# Verify the bootstrap

The only true test is a fresh Omarchy install: an afternoon, a wiped machine, and
impossible from Windows. This is the substitute. Run it **before pushing** any change to
an install script.

Scope: `omarchy-supplement/*.sh` and the `dotfiles` package layout.

Report findings by severity with `file:line` and a concrete fix. Report only things that
would produce a broken machine — not style.

## 1. Syntax

`bash -n` every script (works on Windows). Then `shellcheck` if available.

For Lua in the dotfiles `hypr` package: `luac -p` if available, otherwise read carefully.
Watch for hyphenated Hyprland keys written bare — `tap-to-click = false` parses as
subtraction and must be `["tap-to-click"] = false`.

## 2. Reinventing Omarchy

The most valuable check, and the easiest to miss. For every package and command:

```bash
grep -x <pkg> /usr/share/omarchy/install/omarchy-base.packages   # already shipped?
omarchy install                                                   # official installer?
```

Flag:

- Anything in `PACKAGES` that is already in base — `tmux` `mise` `starship` `fzf`
  `zoxide` `lazygit` `git` `jq` `nvim` `alacritty` `foot` `yay`
- A raw package install where an `omarchy install` entry exists (VS Code, dev
  environments, databases, gaming, services) — the installer also handles theme, secrets,
  and defaults
- Direct `pacman`/`yay` calls instead of `omarchy-pkg-add` / `omarchy-pkg-aur-add`
- Any hand-rolled version manager — Omarchy uses mise via `omarchy install dev-env`
- `xdg-settings` instead of `omarchy default editor|terminal|browser`

## 3. Idempotency — "what happens on the second run?"

| Action | Required guard |
|---|---|
| Package install | `omarchy-pkg-add` (built in) |
| `git clone` | `[[ -d $DIR ]]` |
| Append to a file | `grep -Fxq` |
| `stow` | `--restow` |
| Create user / db / dir | Query or `-e` first |

Flag any unguarded mutation.

## 4. Destructiveness

**No `rm -rf` on anything under `$HOME`.** Conflicts must move to a timestamped backup.
This is what makes the bootstrap safe to re-run on a working machine rather than a fresh
one only. Verify `install-dotfiles.sh` still backs up before stowing.

## 5. Ordering and wiring

- `install-stow.sh` runs **before** `install-dotfiles.sh`
- Children are **executed** (`bash ./x.sh`), never sourced — sourcing lets a child's
  `exit` kill the run and its `set -e` leak into later children
- Every package in `install-dotfiles.sh`'s `PACKAGES` exists in the dotfiles repo
- Every directory in the dotfiles repo is either in `PACKAGES` or deliberately dormant —
  a package not listed silently never deploys
- **`hyprland.lua` is not tracked** in the `hypr` package. It's Omarchy's loader; a
  pinned stale copy breaks future versions.

## 6. Stow conflicts on a fresh machine

For each tracked file, will Stow hit a real file Omarchy already placed? `~/.bashrc` and
`~/.config/hypr/*.lua` both ship with Omarchy, so they *will* conflict — confirm the
backup loop in `install-dotfiles.sh` covers them (it walks every file in the package, so
new packages are handled automatically).

## 7. Unattended safety

`install-all.sh` must run without input. Grep for `--interactive`, bare `read`, and any
package call missing `--noconfirm`. `sudo` is fine.

## 8. Hardcoded values

- `~/dotfiles` is load-bearing (Stow resolves relative to the package parent) — fine, but
  must be consistent
- `REPO_URL` points at `ZiadMohamedAly`, not an upstream fork
- No hardcoded usernames — use `$HOME` / `$USER`
- Machine-specific values (monitor names like `DP-4`) — note as a portability limit, not
  a bug

## Report format

```
🔴 install-packages.sh:14 — `tmux` is already in Omarchy 4 base
   Installing it again is a no-op at best and pins a duplicate at worst.
   Fix: remove from PACKAGES.
```

🔴 breaks a fresh install · 🟠 leaves the machine subtly wrong · 🟡 fragile but works.

## What this cannot catch

Say so explicitly rather than implying completeness:

- Whether a package name actually exists in the repos/AUR
- Whether an `omarchy install <x>` target is spelled right
- Whether Hyprland Lua actually loads — needs `hyprctl reload && hyprctl configerrors`
- Hardware specifics: monitor names, lid behaviour

The real smoke test for a single script is running it twice on the machine. The second run
should change nothing.
