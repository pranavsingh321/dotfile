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
   packages (and sets up oh-my-zsh, zsh-autosuggestions, and tpm).
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

# 2a. Run an interactive bash session in /workspace (mounts $PWD)
docker compose run --rm dottools

# 2b. Or mount a specific project instead of $PWD
PROJECT_DIR=~/some/repo docker compose run --rm dottools

# 2c. Or keep it running in the background and attach/detach as needed
docker compose up -d
docker compose exec dottools bash     # attach anytime
docker compose down                   # stop when done
```

To analyze any project, point `PROJECT_DIR` at it — it is mounted read-write at
`/workspace`, which is also the shell's starting directory.

> On older Docker installs without the compose plugin, use `docker-compose`
> instead of `docker compose`.

Notes:

- Everything is installed via `link_dotfiles.sh` during the build; the shell is
  bash (`CMD ["bash"]`) with `/workspace` as the default directory.
- Tools not packaged by Debian are pulled from upstream releases: helix,
  carapace, uv; plus Python 3.12 + pip from the base image.
- Match host UID/GID so mounted files keep their ownership:
  `USER_ID=$(id -u) GROUP_ID=$(id -g) docker compose build`.
- A named `uv-cache` volume persists Python package caches across runs.

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
| `.config/helix/`            | Helix editor config                |
| `.config/aerospace/`        | AeroSpace window manager config    |
| `.termux/`                  | Termux config                      |
| `chargectl/`                | Battery charge limiter (Termux)    |
| `glazevm/`                  | GlazeWM (Windows) config           |
| `start.bat`                 | Windows startup script             |
| `Dockerfile`, `docker-compose.yml` | Containerized Linux env (see above) |

## Platforms

- **macOS**: Homebrew — shell/CLI tools plus Ghostty and AeroSpace.
- **Linux**: apt — shell/CLI tools; starship/carapace via official installers.
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
