# Conventions

Rules for scripts in this repo. They exist because the only true test is a fresh Omarchy
install — expensive to run, impossible to run from Windows. Conventions substitute for a
test suite.

## Before writing a script at all

**Most additions should not be a new script.** In order of preference:

1. **A line in an existing list** — `PACKAGES` in `install-packages.sh`, `APPS` in
   `install-apps.sh`, `PACKAGES` in `install-dotfiles.sh`. This covers most cases.
2. **An `omarchy install` entry** — Omarchy configures as well as installs.
   Check `omarchy install` for the full list.
3. **A config file in the dotfiles repo** — if it's a file in `$HOME`, it isn't an
   install script.
4. **A new script here** — only for multi-step system state changes with no Omarchy
   equivalent.

Always check first:

```bash
omarchy install                                              # Omarchy's own installers
omarchy                                                      # all 424 commands
grep -x <pkg> /usr/share/omarchy/install/omarchy-base.packages   # already shipped?
```

## Template

```bash
#!/bin/bash
set -euo pipefail

# Dependency checks first — fail fast, with the fix in the message.
if ! command -v foo &>/dev/null; then
  echo "foo is required. Run ./install-foo.sh first." >&2
  exit 1
fi

# Packages: use Omarchy's wrappers, not raw pacman/yay.
omarchy-pkg-add bar baz

# Everything else: guard the action.
TARGET="$HOME/.local/share/foo"
if [[ -d $TARGET ]]; then
  echo "foo already set up"
else
  git clone https://github.com/example/foo "$TARGET"
fi
```

## Non-negotiables

**`set -euo pipefail` at the top of every script.** Scripts are executed, not sourced, so
this stays contained.

**Use Omarchy's package wrappers:**

| | |
|---|---|
| `omarchy-pkg-add` | Official repos. Wraps `pacman -S --noconfirm --needed`, then verifies each package actually landed. |
| `omarchy-pkg-aur-add` | AUR. Wraps `yay -S --noconfirm --needed`. |

Both are already idempotent — no extra guard needed. Don't call `pacman` or `yay`
directly.

**Idempotency — every script must survive a second run.**

| Action | Guard |
|---|---|
| Package install | `omarchy-pkg-add` (built in) |
| `git clone` | `[[ -d $DIR ]]` |
| Append to a file | `grep -Fxq` |
| Create user / db / dir | Query or `-e` test first |
| `stow` | Use `--restow` |
| `systemctl enable` | Naturally idempotent |

**Never delete user data.** Move it to a timestamped backup instead:

```bash
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP" && mv "$target" "$BACKUP/"
```

This is what makes the bootstrap safe on a machine already in use. `rm -rf` on anything in
`$HOME` is not acceptable here.

**No prompts.** `install-all.sh` must run unattended. No `--interactive`, no bare `read`.
Pass explicit flags instead. `sudo` is fine — the user is present at bootstrap.

**Resolve paths from the script, not the working directory:**

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

**Check dependencies with `command -v`**, never `pacman -Qi` — you care whether it runs,
not how it was installed.

**Test commands directly, never `$?` at a distance:**

```bash
if git clone "$REPO_URL" "$DIR"; then ...     # ✅
git clone "$REPO_URL" "$DIR"; if [ $? -eq 0 ] # ❌
```

## Style

Match Omarchy's own conventions — this repo sits next to it:

- Two-space indent, no tabs
- `#!/bin/bash`, never `#!/usr/bin/env bash`
- `[[ ]]` for string/file tests, `(( ))` for numeric
- Inside `[[ ]]`, don't quote variables; do quote string literals
- Quote paths with spaces rather than escaping

## `install-all.sh`

Children are executed, never sourced:

```bash
run() {
  echo "──▶ $1"
  bash "./$1" || { echo "✗ $1 failed" >&2; exit 1; }
}
```

Sourcing would let a child's `exit` kill the whole bootstrap and let its `set -e` leak into
every later child. Ordering constraint: **stow before dotfiles**.

## Verification without running

Development is on Windows; the target is Arch. `pacman`, `omarchy`, `hyprctl`, and `stow`
don't exist here. **Never "verify" by running.**

1. `bash -n script.sh` — syntax, works anywhere
2. `shellcheck script.sh`
3. Read the guard and ask: *what does this do on the second run?*
4. `/verify-bootstrap` for a full audit

On the Arch box, the real smoke test is running a script twice. The second run should be a
fast series of "already installed / already exists" messages and change nothing.

For Hyprland Lua changes, the check is `hyprctl reload && hyprctl configerrors` — repeat
until clean.
