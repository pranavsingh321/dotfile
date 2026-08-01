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
| `glazevm/`                  | GlazeWM (Windows) config           |
| `start.bat`                 | Windows startup script             |

## Platforms

- **macOS**: Homebrew — shell/CLI tools plus Ghostty and AeroSpace.
- **Linux**: apt — shell/CLI tools; starship/carapace via official installers.
- **Termux**: `pkg` — shell/CLI tools.

## Notes

- The install script is idempotent; rerunning it only installs missing items.
- Secrets live in `~/.secret` (ignored by git); use `.secret_sample` as a template.
