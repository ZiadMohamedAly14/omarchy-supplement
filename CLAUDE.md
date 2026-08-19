# omarchy-supplement

Post-install bootstrap for a fresh **Omarchy 4** machine. One command takes a stock
install to my setup.

This is a deliberately small starter. It is meant to grow — most files are near-empty
lists with commented examples.

## The pair

| Repo | Role |
|---|---|
| **omarchy-supplement** (this repo) | **Imperative.** Installs packages, runs Omarchy's installers, links the dotfiles. |
| **[dotfiles](https://github.com/ZiadMohamedAly14/dotfiles)** | **Declarative.** The config files themselves, deployed by GNU Stow. |

Rule: **changes system state → here. A file that lives in `$HOME` → dotfiles.**

In Omarchy 4 the dotfiles repo carries most of the weight. All customisation — including
Hyprland — is now just files in `~/.config/`, which is exactly what Stow handles. This
repo stays thin on purpose.

**[docs/GUIDE.md](docs/GUIDE.md) is the orientation doc** — the goal, where things go, and
common workflows end to end. Read it when the task is "add X to my setup" and you're not
sure which repo or which list it belongs in.

See also [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how they combine, and
[docs/CONVENTIONS.md](docs/CONVENTIONS.md) for script rules.

---

## Omarchy 4 facts that drive every decision here

**Read these before writing anything.** Omarchy 4 differs sharply from 3, and most
tutorials and prior habits are wrong now.

### Hyprland is configured in Lua

`~/.config/hypr/` holds Lua, not `hyprland.conf`. Omarchy ships five files there that are
**yours to edit** — they are `require`d *after* Omarchy's defaults, so they override
cleanly:

```
~/.config/hypr/hyprland.lua     loader — Omarchy's, leave it alone
              bindings.lua      ← yours
              monitors.lua      ← yours
              input.lua         ← yours
              looknfeel.lua     ← yours
              autostart.lua     ← yours
```

There is no source-line hack and no config patching. The five override files are stowed
from the dotfiles repo. `hyprland.lua` is deliberately **not** stowed so Omarchy can
evolve the loader.

The API is `o.*` (Omarchy helpers) and `hl.*` (Hyprland):

```lua
o.bind("SUPER + E", "Editor", { launch = "code" })   -- { launch = } wraps with uwsm-app
hl.unbind("SUPER + F")                                -- ALWAYS unbind before rebinding
hl.config({ input = { kb_options = "ctrl:nocaps" } })
hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })
o.window("qemu", { workspace = "5" })
o.launch_on_start("my-service")
```

**Bindings stack, they do not replace.** Binding an already-bound key gives two actions on
one press. Check with `omarchy menu keybindings --print`, then `hl.unbind()` first.

Validate every change: `hyprctl reload && hyprctl configerrors`.

### Omarchy has a CLI — check it before writing a script

424 commands under an `omarchy` router. Most things you'd hand-roll already exist:

| Instead of | Use |
|---|---|
| `yay -S --noconfirm --needed` | `omarchy-pkg-add` (repos) · `omarchy-pkg-aur-add` (AUR) |
| Hand-rolled Node/Ruby/Go install | `omarchy install dev-env <lang>` — 18 languages via mise |
| Hand-rolled VS Code install | `omarchy install editor-vscode` — also theme, secrets, auto-update off |
| `xdg-settings set default-*` | `omarchy default editor\|terminal\|browser` |
| A systemd unit for login tasks | `~/.config/omarchy/hooks/<event>.d/` or `o.launch_on_start()` |

Browse with `omarchy` and `omarchy install`. **Prefer an Omarchy installer over a raw
package install** — they configure as well as install.

### These are already in base — never install them

Verified against `omarchy-base.packages` on Omarchy 4.0.0:

`tmux` `mise` `starship` `fzf` `zoxide` `lazygit` `git` `jq` `nvim` `foot` `yay`
`docker` `docker-compose` `docker-buildx` `lazydocker` `ripgrep` `fd` `bat` `eza`

**`alacritty` is NOT in base** — it is `omarchy install terminal alacritty`, which
also sets it as the default terminal. Same for `ghostty` and `kitty`. Only `foot`
ships by default.

Also not in base: `stow` `zsh` `yazi` `postgresql` `gh`.

Check before adding: `grep -x <pkg> /usr/share/omarchy/install/omarchy-base.packages`

### The shell is bash

Omarchy 4 ships `default/bash/` (aliases, functions, completions, env bootstrap) and
`~/.bashrc` is documented as yours and never overwritten. The stowed `.bashrc` keeps
Omarchy's three bootstrap lines at the top and adds personal config below. **Do not
reorder or remove those lines** — `env-bootstrap` sets `OMARCHY_PATH`.

### Omarchy ships its own agent skills

`/usr/share/omarchy/default/agents/skills/` — `omarchy/hyprland.md`, `omarchy/hooks.md`,
`omarchy/theming.md`, `omarchy/plugins.md`, `omarchy/capture.md`, `diagnose-crash/`.

**Read the relevant one before working on that area.** They are authoritative and version
with the system. Do not duplicate them here.

---

## Invariants

1. **Dotfiles clone to `~/dotfiles`.** Stow resolves symlinks relative to the package's
   parent directory. Move it and every link dangles.
2. **A package deploys only if it is in the `PACKAGES` array in `install-dotfiles.sh`.**
   Adding a directory to the dotfiles repo does nothing on its own.
3. **Never stow `hyprland.lua`.** It is Omarchy's loader. Stowing a stale copy breaks
   future versions.
4. **Everything is idempotent and non-destructive.** `install-dotfiles.sh` moves conflicts
   to a timestamped backup rather than deleting. Keep it that way.

---

## What runs

```
./install-all.sh
  ├─ preflight.sh           pacman -Syu                 ← must precede everything
  ├─ remove-preinstalls.sh  omarchy remove preinstalls  ← must precede packages
  ├─ install-stow.sh        stow — not in base          ← must precede dotfiles
  ├─ install-packages.sh    extra Arch packages (list to grow)
  ├─ install-apps.sh        `omarchy install ...` (list to grow)
  └─ install-dotfiles.sh    clone ~/dotfiles, back up conflicts, stow packages
```

Children are **executed, not sourced**, so a failure in one cannot corrupt the parent
shell or silently abort the run.

**`omarchy-pkg-add` does not refresh pacman's databases.** It calls `pacman -S` directly,
and a fresh Omarchy machine can boot with no sync databases at all — every install then
fails with `error: target not found`, including `stow`. That is what `preflight.sh` is
for. Verified the hard way on a real fresh install.

**Never call `pacman -Syu` directly.** Omarchy ships a pacman pre-transaction hook that
aborts the transaction and tells you to use `omarchy update`, which also snapshots,
refreshes keyrings, runs migrations, fires post-update hooks, and does the restart check.
The `OMARCHY_ALLOW_DIRECT_PACMAN=1` bypass it mentions skips all of that — don't use it.
A bare `pacman -Sy` slips past the hook but leaves a partial-upgrade state.

**`remove-preinstalls.sh` breaks the "already in base" shortcut.** It strips Omarchy's
preinstalled set, and that set overlaps the base package list — `lazydocker` is in
`omarchy-base.packages` and still gets removed. So a package being in base is no longer
sufficient reason to leave it out of `install-packages.sh`. Anything wanted back must be
listed there explicitly, and the list is checked against *what the removal actually took
out*, not against the base list. Skip the removal entirely with
`OMARCHY_KEEP_PREINSTALLS=1 ./install-all.sh`.

---

## Working here

- **New tool** → `/add-software`. Check `omarchy install` and the base package list
  first; most of the time no new script is needed, just a list entry.
- **Capture a config** → `/capture-dotfile`. Goes to the dotfiles repo, plus the
  `PACKAGES` array here.
- **Before pushing** → `/verify-bootstrap`. The only real test is a fresh install, so
  static review substitutes.
- **After `omarchy update`** → `/sync-omarchy-drift`.

## Development happens on Windows

The repos live on `D:\Repos\my-omarchy-setup\`; the scripts only ever run on the Arch box.
`pacman`, `omarchy`, `hyprctl`, `stow` do not exist here. **Never verify by running.** Use
`bash -n`, `shellcheck`, and read the guards. On the machine, the real smoke test is
running a script twice — the second run should change nothing.
