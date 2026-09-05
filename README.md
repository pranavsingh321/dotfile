# Dotfiles

My personal dotfiles and setup scripts. Configures the shell, terminal tools,
and window manager on macOS, Linux, and Termux.

## Usage

Clone the repo into `~/dotfile` and run the setup script from that directory:

```sh
git clone https://github.com/yourname/dotfile.git ~/dotfile
cd ~/dotfile
./link_dotfiles.sh
```

The script:

1. Runs `install.sh`, which detects the platform and installs all required
   packages (and sets up tpm).
2. Copies the secret sample to `~/.secret` (edit it with your real secrets).
3. Copies the helix and termux config folders.
4. Symlinks the remaining dotfiles into `$HOME`.

To install packages only, run `./install.sh` on its own.

## Docker (portable analysis environment)

A Linux container (Python 3.12 base) with all the dotfiles applied — useful for
analyzing a project with the same toolset anywhere, without touching the host.

### Build and run with Compose

From this repo directory:

```sh
# 1. Build the image
docker compose build
```

The `ide` command wraps the compose setup so you can launch the environment
from **any** directory — no need to `cd` into this repo:

```sh
ide [options] [SUBCOMMAND] [command...]

Options:
  --rm               remove the container on exit (default)
  --no-rm            keep the container after exit
  -m, --mount PATH   mount PATH instead of the current directory

Subcommands:
  run (default)      shell in $PWD (or -m PATH) mounted at /workspace
  up                 start detached (then: ide attach)
  attach             attach to the running container
  stop               stop the container (keep it)
  down               stop and remove container (home volume persists)
  rebuild            rebuild the image (host UID/GID) and run
```

Examples:

```sh
ide                        # ephemeral shell in $PWD
ide --no-rm                # shell that stays after exit
ide -m ~/proj/some/repo    # work on a specific repo without cd-ing into it
ide up && ide attach       # persistent background session
```

`ide` auto-detects podman (fallback: docker); it mounts the chosen directory at
`/workspace`, persists your dev home, and mounts `~/.ssh` and `~/.secret`
read-only into the container when present.

Running compose directly works too:

```sh
# Interactive session in /workspace (mounts $PWD)
docker compose run --rm dottools

# Or mount a specific project instead of $PWD
PROJECT_DIR=~/some/repo docker compose run --rm dottools

# Or keep it running in the background and attach/detach as needed
docker compose up -d
docker compose exec dottools bash     # attach anytime
docker compose down                   # stop when done
```

To analyze any project, point `PROJECT_DIR` at it — it is mounted read-write at
`/workspace`, which is also the shell's starting directory.

> On older Docker installs without the compose plugin, use `docker-compose`
> instead of `docker compose`.

Notes:

- `link_dotfiles.sh` runs during the build: it links all dotfiles and, via
  `install.sh`, installs the CLI tools and every LSP server / formatter referenced
  by `.config/helix/languages.toml` (rust-analyzer, pyright, ruff, gopls+gofmt,
  jdtls, marksman, bash-language-server + shfmt, typescript-language-server +
  prettier, and the vscode-html/css/json language servers). `install.sh` is the
  single source of truth for tool installs; `rust-analyzer`, `marksman`, and
  `carapace` are prebuilt binaries (no rustup/rustc, no Go build).
- `openssh-client` is installed so `git pull`/clone over SSH works inside the
  container; mount or copy `~/.ssh` keys in for private repos.
- Sessions survive restarts: the `dotfiles-home` volume keeps bash history,
  tmux resurrect/continuum saves (auto-restored on login), caches, and helix
  state across `down`/`up` and even across `ide run` invocations.
- Match host UID/GID so mounted files keep their ownership:
  `USER_ID=$(id -u) GROUP_ID=$(id -g) docker compose build`.
- `uv-cache` persists the Python package cache; `dotfiles-home` persists the rest.

### Save / load the image as a file

To copy the built image to another machine, export it as a tarball:

```sh
podman save -o dottools.tar dottools:latest      # export
podman load -i dottools.tar                      # import on the target
```

## Architecture Documentation (Banneker)

Automated codebase analysis and architecture diagrams using [Banneker](https://www.npmjs.com/package/banneker).

### Setup

```sh
# Install Banneker commands into opencode
npx banneker --opencode
```

### Generate Documentation

**Via CLI script:**

```sh
# Run all steps (document → roadmap → appendix)
./banneker-run.sh

# Or run individual steps
./banneker-run.sh document    # Analyze codebase
./banneker-run.sh roadmap     # Generate diagrams
./banneker-run.sh appendix    # Compile HTML reference
./banneker-run.sh feed        # Export artifacts
```

**Via opencode slash commands:**

```sh
/banneker:document    # Analyze codebase
/banneker:roadmap     # Generate diagrams
/banneker:appendix    # Compile HTML reference
/banneker:feed        # Export artifacts
```

### View Diagrams

```sh
# Open diagrams in browser
xdg-open .banneker/diagrams/executive-roadmap.html
xdg-open .banneker/diagrams/decision-map.html
xdg-open .banneker/diagrams/system-map.html
xdg-open .banneker/diagrams/architecture-wiring.html
```

### Available Commands

| Command | Description |
|---------|-------------|
| `/banneker:document` | Analyze existing codebase |
| `/banneker:survey` | Discovery interview (new projects) |
| `/banneker:architect` | Generate planning documents |
| `/banneker:roadmap` | Generate architecture diagrams |
| `/banneker:appendix` | Compile HTML reference |
| `/banneker:feed` | Export to downstream frameworks |
| `/banneker:audit` | Evaluate planning documents |
| `/banneker:help` | Show all commands |
| `/banneker:progress` | Check workflow status |

## Included configs

| File / dir                  | Purpose                            |
| --------------------------- | ---------------------------------- |
| `.zshrc`, `.bashrc`         | Zsh / Bash shell config            |
| `.bashrc_mac`               | Bash config for macOS              |
| `.gitconfig`                | Git config                         |
| `.tmux.conf`                | tmux + tpm plugins                 |
| `switch-session-fzf.sh`     | tmux session switcher (fzf)        |
| `ide`                       | Launch the container from any dir  |
| `.config/helix/`            | Helix editor config                |
| `.config/aerospace/`        | AeroSpace window manager config    |
| `.termux/`                  | Termux config                      |
| `chargectl/`                | Battery charge limiter (Termux)    |
| `glazevm/`                  | GlazeWM (Windows) config           |
| `start.bat`                 | Windows startup script             |
| `Dockerfile`, `docker-compose.yml` | Containerized Linux env (see above) |

## Platforms

- **macOS**: Homebrew — shell/CLI tools plus Ghostty and AeroSpace.
- **Linux**: apt — shell/CLI tools; helix, starship, carapace, rust-analyzer, and
  marksman via official/prebuilt installers.
- **Termux**: `pkg` — shell/CLI tools.

## Notes

- The install script is idempotent; rerunning it only installs missing items.
- Secrets live in `~/.secret` (ignored by git); use `.secret_sample` as a template.

## Chargectl (battery limiter)

Root-only daemon for the phone: stops charging at 90%, resumes below 30% (as a
notification), by writing `1`/`0` to `/sys/class/power_supply/battery/input_suspend`.

**Install** — running `./link_dotfiles.sh` on Termux copies these automatically:

```sh
cp chargectl/chargectl.sh ~/chargectl.sh        # the daemon (fixed path)
cp chargectl/chargectl ~/chargectl              # control script
cp chargectl/termux-login.sh ~/.termux/termux-login.sh   # autostart on login
chmod 700 ~/chargectl.sh ~/chargectl ~/.termux/termux-login.sh
```

**Start / control**:

```sh
~/chargectl start     # launch the daemon
~/chargectl status    # daemon + battery status + input_suspend
~/chargectl stop
~/chargectl log       # tail ~/chargectl.log
```

**Boot autostart** — `~/.termux/termux-login.sh` starts it on login. For a true
boot-time start (works even if Termux never opens), use the Magisk module in
`chargectl/magisk-module/` — it runs `~/chargectl.sh` as root at boot and waits
for `/data` to be decrypted first:

```sh
cd chargectl/magisk-module
zip -r /sdcard/chargectl-module.zip module.prop service.sh
su -c 'magisk --install-module /sdcard/chargectl-module.zip'
reboot
```

**Troubleshooting** — if the phone charges past 90%, the daemon isn't running:
`~/chargectl status` prints `daemon: stopped`. Start it, then verify the node is
writable (`echo 1 > /sys/class/power_supply/battery/input_suspend`).
