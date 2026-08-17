# The Guide

Start here. This explains what the two repos are for, how to move between them, and what
you need to know before changing anything.

- **This doc** — orientation and workflows
- [ARCHITECTURE.md](ARCHITECTURE.md) — how the pieces fit, and why
- [CONVENTIONS.md](CONVENTIONS.md) — rules for writing scripts
- [../CLAUDE.md](../CLAUDE.md) — the condensed rules Claude Code reads every session

---

## 1. The goal

**Reinstall Omarchy and be back to a machine that feels like mine in one command.**

That's it. Not a distro, not a framework — a repeatable way to close the gap between
"stock Omarchy" and "my setup" without hand-tweaking forty settings from memory.

Two failure modes this is designed to avoid:

- **Forgetting.** You configure something clever on a Tuesday, reinstall in March, and the
  cleverness is gone because it only ever lived in `~/.config`.
- **A bootstrap you're afraid to run.** If the script might destroy a working machine, you
  won't run it, and it rots. So nothing here deletes anything — conflicts get moved to a
  timestamped backup. It's safe to run on a machine you're actively using.

Secondary goal: **stay close to Omarchy.** Every line of custom code is a line that breaks
on the next release. Where Omarchy offers a way to do something, use it.

---

## 2. The mental model

Three layers. Each only knows about the one below it.

```
┌────────────────────────────────────────────────────────────┐
│  dotfiles              declarative — files that ARE        │
│  ~/dotfiles/{bash,hypr}  →  symlinked into $HOME           │
├────────────────────────────────────────────────────────────┤
│  omarchy-supplement    imperative — scripts that DO        │
│  install packages · run Omarchy installers · stow          │
├────────────────────────────────────────────────────────────┤
│  Omarchy 4             upstream — /usr/share/omarchy       │
│  never edited, only overlaid                               │
└────────────────────────────────────────────────────────────┘
```

**The one rule that decides which repo anything goes in:**

> Changes system state → **omarchy-supplement**.
> A file that lives in `$HOME` → **dotfiles**.

Installing `yazi` is system state. Your `yazi` config is a file in `$HOME`. They go in
different repos, and that's the whole split.

### Why two repos and not one

They fail differently.

Dotfiles change constantly and fail *loudly* — you tweak a keybind, it's wrong, you notice
in ten seconds. Install scripts change rarely and fail *silently* — a bug sits undetected
until your next fresh install, months later, when you have no working machine to debug
from.

Keeping them apart means dotfiles history stays readable as a config log, and the install
path stays small enough to audit by eye. It also means you can blow away the supplement
clone after bootstrap without losing anything.

---

## 3. Map of both repos

### omarchy-supplement — the doer

```
install-all.sh          ← entry point; runs the four below in order
install-stow.sh           GNU Stow (the only hard prerequisite)
install-packages.sh       PACKAGES[] / AUR_PACKAGES[]   ← your Arch packages
install-apps.sh           APPS[]                        ← your Omarchy installers
install-dotfiles.sh       clone ~/dotfiles, back up conflicts, stow    ← PACKAGES[]

README.md               how to install and extend
CLAUDE.md               rules for Claude Code
docs/GUIDE.md           this file
docs/ARCHITECTURE.md    how it works and why
docs/CONVENTIONS.md     how to write scripts here
.claude/skills/         four workflows, see §7
```

Three of those files are **lists you fill in**, not code you rewrite. That's the design:

| File | Array | Holds |
|---|---|---|
| `install-packages.sh` | `PACKAGES` / `AUR_PACKAGES` | Plain Arch package names |
| `install-apps.sh` | `APPS` | Arguments to `omarchy install` |
| `install-dotfiles.sh` | `PACKAGES` | Stow package names |

### dotfiles — the data

```
bash/.bashrc                      → ~/.bashrc
hypr/.config/hypr/bindings.lua    → ~/.config/hypr/bindings.lua
                   monitors.lua
                   input.lua
                   looknfeel.lua
                   autostart.lua
```

Every top-level directory is a **Stow package** whose interior mirrors `$HOME` exactly.
`stow hypr` from `~/dotfiles` creates the symlinks on the right.

Two consequences worth internalising:

1. **The clone must be at `~/dotfiles`** — Stow computes link targets relative to the
   package's parent directory.
2. **Editing the live file edits the repo file**, because the live path is a symlink into
   the repo. There is no copy-back step. Just `cd ~/dotfiles && git commit`.

---

## 4. Where does this go?

The navigation question, as a decision tree.

```
Something you want on every fresh machine
│
├─ Is it a FILE in $HOME?  ────────────────────────────► dotfiles repo
│    │                                                    (+ add to PACKAGES in
│    │                                                     install-dotfiles.sh)
│    ├─ Hyprland keybind/monitor/input/look/autostart?
│    │       → edit the existing hypr package, don't make a new one
│    ├─ Shell alias, export, function?
│    │       → append to bash/.bashrc, below the bootstrap block
│    └─ Anything else in ~/.config?
│            → new Stow package
│
└─ Does it CHANGE THE SYSTEM?  ───────────────────────► omarchy-supplement
     │
     ├─ Already in Omarchy 4 base?     → do nothing, you have it
     ├─ Omarchy has an installer?      → APPS[] in install-apps.sh
     ├─ Plain Arch package?            → PACKAGES[] in install-packages.sh
     ├─ Just a default app?            → omarchy default … in install-apps.sh
     └─ Multi-step system change?      → new install-<thing>.sh (rare)
```

**Check these before adding anything:**

```bash
grep -x <package> /usr/share/omarchy/install/omarchy-base.packages   # already shipped?
omarchy install                                                       # official installer?
omarchy                                                               # all 424 commands
```

Already in base — never install these (verified on Omarchy 4.0.0):

`tmux` `mise` `starship` `fzf` `zoxide` `lazygit` `git` `jq` `nvim` `foot` `yay`
`docker` `docker-compose` `docker-buildx` `lazydocker` `ripgrep` `fd` `bat` `eza`

Not in base, fair game: `stow` `zsh` `yazi` `postgresql` `gh`

**Terminals are the trap.** Only `foot` is in base. `alacritty`, `ghostty`, and
`kitty` are installers — `omarchy install terminal <name>` — which also set the
default terminal and `SUPER+Return`. Don't `pacman -S` them.

---

## 5. Common workflows

### Fresh machine

```bash
git clone https://github.com/ZiadMohamedAly14/omarchy-supplement.git ~/omarchy-supplement
cd ~/omarchy-supplement && ./install-all.sh
```

Then log out and back in. The supplement pulls the dotfiles repo itself, so this URL is
the only one to remember.

Anything Omarchy already placed (`~/.bashrc`, the `hypr` Lua files) gets moved to
`~/.dotfiles-backup-<timestamp>/` before being replaced with a symlink. Nothing is deleted.

### "I want VS Code on every machine"

`install-apps.sh`:

```bash
APPS=(
  "editor-vscode"
)
```

and uncomment `omarchy default editor code` at the bottom. Omarchy's installer also wires
up the theme, secret storage, and disables VS Code's self-updater — which is why this beats
`pacman -S code`.

### "I want yazi"

Not in base, no Omarchy installer. `install-packages.sh`:

```bash
PACKAGES=(
  yazi
)
```

### "I want Node"

Never hand-roll a version manager. Omarchy uses mise:

```bash
APPS=(
  "dev-env node"
)
```

`omarchy install dev-env` covers 18 languages.

### "I changed a keybind and want to keep it"

Hyprland config is already tracked, so edit it in the repo (or on the machine — same file
via symlink):

```lua
-- ~/dotfiles/hypr/.config/hypr/bindings.lua
hl.unbind("SUPER + F")                                 -- was: fullscreen
o.bind("SUPER + F", "File manager", { launch = "nautilus" })
```

Then `hyprctl reload && hyprctl configerrors`, and commit from `~/dotfiles`.

### "I want to track a new config file"

Two steps, and **skipping the second is the most common mistake**:

1. Create the package in the dotfiles repo:
   `~/dotfiles/alacritty/.config/alacritty/alacritty.toml`
2. Add it to `PACKAGES` in `install-dotfiles.sh`:

```bash
PACKAGES=(
  bash
  hypr
  alacritty     # ← without this it never deploys
)
```

Then `stow --restow alacritty`, and commit both repos.

### After `omarchy update`

Run the `/sync-omarchy-drift` skill. It checks for new default keybinds colliding with
yours, packages newly absorbed into base, and configs reverted by `omarchy refresh`.

---

## 6. What to know about Omarchy 4

The five things that most often cause wrong assumptions.

### Hyprland is configured in Lua, and overrides are a designed feature

No config patching, no appended source lines. Omarchy ships `~/.config/hypr/hyprland.lua`
as a loader that requires its own defaults, *then* your five files:

```
hyprland.lua    ← Omarchy's loader. NOT tracked, deliberately.
bindings.lua  monitors.lua  input.lua  looknfeel.lua  autostart.lua   ← yours, tracked
```

`hyprland.lua` stays untracked so Omarchy can change the loader between versions. Pinning
a stale copy would break the boot path.

The API is `o.*` (Omarchy helpers) and `hl.*` (Hyprland):

```lua
o.bind("SUPER + E", "Editor", { launch = "code" })   -- { launch = } wraps with uwsm-app
hl.unbind("SUPER + F")
hl.config({ input = { kb_options = "ctrl:nocaps" } })
hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })
o.window("qemu", { workspace = "5" })
o.launch_on_start("my-service")
```

**Bindings stack — they do not replace.** Binding an already-bound key leaves *two* actions
firing on one press. Always `hl.unbind()` first. Check with
`omarchy menu keybindings --print`.

**Validate every change:** `hyprctl reload && hyprctl configerrors`. Repeat until clean.

**Never trust remembered window-rule syntax** — it changes between Hyprland versions. Fetch
the wiki page first.

Hyphenated Hyprland keys need bracket syntax in Lua, since `tap-to-click` parses as
subtraction:

```lua
["tap-to-click"] = false
```

### Omarchy has 424 commands — check before writing anything

| Instead of | Use |
|---|---|
| `yay -S --noconfirm --needed` | `omarchy-pkg-add` · `omarchy-pkg-aur-add` |
| Hand-rolled Node/Ruby/Go install | `omarchy install dev-env <lang>` |
| `pacman -S code` + config | `omarchy install editor-vscode` |
| `xdg-settings set default-*` | `omarchy default editor\|terminal\|browser` |
| A systemd unit for login tasks | `o.launch_on_start()` or a hook |

### The shell is bash

Omarchy ships `default/bash/` (aliases, functions, completions) and documents `~/.bashrc`
as yours, never overwritten. The tracked `.bashrc` keeps Omarchy's three bootstrap lines at
the top — **do not reorder or remove them**, `env-bootstrap` is what sets `OMARCHY_PATH`.

Check what already exists before adding an alias: `ls /usr/share/omarchy/default/bash/`

### Omarchy ships its own agent skills

`/usr/share/omarchy/default/agents/skills/` — `omarchy/hyprland.md`, `hooks.md`,
`theming.md`, `plugins.md`, `capture.md`, plus `diagnose-crash/`.

These are authoritative and version with the system. **Read the relevant one before working
in that area**, and don't duplicate them into this repo.

### `omarchy refresh` writes *through* symlinks

`omarchy refresh hyprland` and `omarchy reinstall configs` do `cp -f` onto
`~/.config/...`. If the target is a Stow symlink, the copy lands in **your repo**, replacing
your file with Omarchy's default.

Only explicit commands do this — never a plain `omarchy update` — and `git diff` shows
exactly what changed. If a config mysteriously reverts, this is why. Recover with
`git checkout`.

---

## 7. Working with Claude Code

Four skills live in `.claude/skills/`. They're committed with the repo, so they work on any
machine that clones it.

| Skill | Use when |
|---|---|
| `/add-software` | Adding a package, app, runtime, or service. Routes you to the right list instead of writing a script. |
| `/capture-dotfile` | Tracking a config file. Handles **both** repos so the wiring isn't forgotten. |
| `/verify-bootstrap` | Before pushing. Static audit of the fresh-install path. |
| `/sync-omarchy-drift` | After `omarchy update`. Finds collisions, redundancy, and reverted files. |

`/verify-bootstrap` is the one that earns its keep. There's no test suite here and the only
real test is wiping a machine — so a static audit before pushing is worth more than it
would be in a normal repo.

### Development is on Windows, execution is on Arch

The repos live on `D:\Repos\my-omarchy-setup\`. `pacman`, `omarchy`, `hyprctl`, and `stow`
do not exist there. **Never verify by running.** Use `bash -n`, `shellcheck`, and read the
guards.

On the machine, the real smoke test for any script is **running it twice** — the second run
should be a fast series of "already installed" messages and change nothing.

---

## 8. Rules that must not be broken

1. **`~/dotfiles` is the clone path.** Stow resolves symlinks relative to the package's
   parent directory. Move it and every link dangles.
2. **A Stow package deploys only if it's in `PACKAGES` in `install-dotfiles.sh`.** Creating
   a directory in the dotfiles repo does nothing on its own.
3. **Never track `hyprland.lua`.** It's Omarchy's loader.
4. **Never `rm -rf` anything in `$HOME`.** Move it to a timestamped backup. This is what
   makes the bootstrap safe to re-run on a working machine.
5. **Never edit `/usr/share/omarchy`.** It's a pacman package; changes vanish on update.
   Override in `~/.config` instead.
6. **`install-all.sh` executes children, never sources them.** Sourcing lets a child's
   `exit` kill the whole run and its `set -e` leak into every later script.
7. **Keep the Omarchy bootstrap block at the top of `.bashrc`.**
8. **No prompts in the bootstrap.** No `--interactive`, no bare `read`. It must run
   unattended.
9. **LF line endings.** `.gitattributes` enforces this — a CRLF shell script dies on Linux
   with `bad interpreter: /bin/bash^M`.
10. **Shell scripts need the exec bit.** Set it in the index with
    `git update-index --chmod=+x`, since Windows won't.

---

## 9. Quick reference

```bash
# Bootstrap
git clone https://github.com/ZiadMohamedAly14/omarchy-supplement.git ~/omarchy-supplement
cd ~/omarchy-supplement && ./install-all.sh

# Is it already shipped?
grep -x <pkg> /usr/share/omarchy/install/omarchy-base.packages
omarchy install                       # official installers
omarchy                               # all commands

# Hyprland
omarchy menu keybindings --print      # what's bound
hyprctl monitors all                  # outputs and modes
hyprctl reload && hyprctl configerrors

# Stow
cd ~/dotfiles && stow --restow <package>
cd ~/dotfiles && git status           # did omarchy refresh clobber something?

# Reset a config to Omarchy's default (backs yours up first)
omarchy refresh hyprland
```

| Path | What |
|---|---|
| `~/omarchy-supplement/` | This repo. Nothing reads it after bootstrap. |
| `~/dotfiles/` | Stow packages; symlink targets |
| `/usr/share/omarchy/` | Omarchy itself (`$OMARCHY_PATH`). Never edit. |
| `~/.config/hypr/*.lua` | Hyprland overrides (symlinks) |
| `~/.bashrc` | Shell (symlink) |
| `~/.dotfiles-backup-<ts>/` | Whatever Stow displaced |
