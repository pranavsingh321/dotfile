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
