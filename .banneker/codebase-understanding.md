# Codebase Understanding: Dotfile

Generated: 2026-08-25
Analyzed by: Banneker Cartographer

---

## Project Metadata

**Type:** shell-script (infrastructure/dotfiles)
**Primary Language:** Bash
**Framework:** None (shell scripts + Docker)
**Version:** Unknown
**Monorepo:** No

**Scale:**
- Files: ~28 (excluding .git)
- Lines of code: ~500 (estimate)
- Directories scanned: 4

**Analyzed:** 2026-08-25T11:25:00Z

---

## Directory Structure

```
.
├── chargectl/
│   ├── magisk-module/
│   │   ├── module.prop
│   │   └── service.sh
│   ├── chargectl
│   ├── chargectl.sh
│   └── termux-login.sh
├── glazevm/
│   └── config.yaml
├── .config/
│   ├── aerospace/
│   │   └── aerospace.toml
│   └── helix/
│       ├── config.toml
│       └── languages.toml
├── .termux/
│   └── boot/start-crypto.sh
├── Dockerfile
├── docker-compose.yml
├── install.sh
├── link_dotfiles.sh
├── start.bat
├── switch-session-fzf.sh
├── README.md
├── .bashrc
├── .bashrc_mac
├── .gitconfig
├── .gitignore
├── .NERDTreeBookmarks
├── .secret_sample
├── .tmux.conf
└── .zshrc
```

**Key directories:**
- `chargectl/` — Battery charge limiter daemon for Termux (root-only)
- `glazevm/` — GlazeWM window manager config (Windows)
- `.config/helix/` — Helix editor configuration
- `.config/aerospace/` — AeroSpace tiling window manager config (macOS)
- `.termux/` — Termux-specific configs and boot scripts

---

## Technology Stack

### Frontend

None detected

### Backend

None detected

### Shell & CLI Tools

| Technology | Version | Purpose |
|------------|---------|---------|
| Bash | 5.x | Primary scripting language |
| Zsh | 5.9 | Shell (via oh-my-zsh) |
| tmux | 3.5 | Terminal multiplexer |
| fzf | 0.60 | Fuzzy finder |
| bat | 0.25 | Cat replacement |
| ripgrep | 14.1 | Fast grep |
| starship | 1.22 | Cross-shell prompt |
| carapace | 1.7.3 | Shell completion |
| zoxide | 0.9.7 | Smart cd |
| helix | 25.07 | Modal editor |
| neovim | 0.10.4 | Modal editor |
| jq | 1.7.1 | JSON processor |
| gh | 2.46 | GitHub CLI |
| uv | 0.12.5 | Python package manager |

### Infrastructure

| Technology | Version | Purpose |
|------------|---------|---------|
| Docker | latest | Containerized analysis environment |
| Docker Compose | latest | Multi-service orchestration |
| Python | 3.12 | Base image for Docker |
| Magisk | N/A | Android root module for boot autostart |

### Platform-Specific

| Technology | Platform | Purpose |
|------------|----------|---------|
| Homebrew | macOS | Package manager |
| AeroSpace | macOS | Tiling window manager |
| Ghostty | macOS | Terminal emulator |
| Termux | Android | Terminal emulator |
| GlazeWM | Windows | Tiling window manager |

---

## Key Patterns Detected

### Architecture Pattern

**Infrastructure-as-Code (Dotfiles Repository)**

Single-person dotfiles repository with cross-platform support (macOS, Linux, Termux/Android, Windows). Organized as:
- Shell configs (`.bashrc`, `.zshrc`, `.tmux.conf`)
- Editor configs (`.config/helix/`, neovim)
- Window manager configs (`.config/aerospace/`, `glazevm/`)
- Platform-specific installers (`install.sh` with platform detection)
- Docker container for portable analysis environments

### API Communication

None detected (static configuration files)

### State Management

None detected (files are static configs, not applications)

### Routing

None detected

### Data Flow

**Setup Flow:**
1. User clones repo to `~/dotfile`
2. Runs `link_dotfiles.sh` which:
   - Calls `install.sh` (detects platform, installs packages)
   - Copies helix/termux configs to `~/.config/`
   - Symlinks dotfiles into `$HOME`
   - Installs chargectl on Termux

**Docker Flow:**
1. `docker compose build` builds image with all tools
2. `docker compose run --rm dottools` mounts project at `/workspace`
3. All tools pre-installed and configured

---

## Entry Points

**Main entry points:**
- `install.sh` — Platform-specific package installer (macOS/Linux/Termux)
- `link_dotfiles.sh` — Dotfile symlinker and setup orchestrator
- `Dockerfile` — Container build definition
- `docker-compose.yml` — Container orchestration

**Scripts:**
- `install.sh`: Detects platform, installs packages via apt/brew/pkg
- `link_dotfiles.sh`: Runs install.sh, symlinks configs, copies directories
- `switch-session-fzf.sh`: tmux session switcher using fzf
- `chargectl/chargectl.sh`: Battery charge limiter daemon (Termux)
- `chargectl/termux-login.sh`: Autostart hook for Termux login

---

## Configuration Files

| File | Purpose |
|------|---------|
| `.bashrc` | Bash shell configuration (Linux/macOS) |
| `.bashrc_mac` | Bash config specific to macOS |
| `.zshrc` | Zsh shell configuration |
| `.tmux.conf` | tmux configuration with tpm plugins |
| `.gitconfig` | Git user configuration |
| `.gitignore` | Git ignore rules |
| `.config/helix/config.toml` | Helix editor settings |
| `.config/helix/languages.toml` | Helix language server config |
| `.config/aerospace/aerospace.toml` | AeroSpace window manager config |
| `.secret_sample` | Template for secrets (copied to ~/.secret) |
| `Dockerfile` | Python 3.12-slim based analysis environment |
| `docker-compose.yml` | Container service definition with volumes |
| `glazevm/config.yaml` | GlazeWM config (Windows) |
| `chargectl/magisk-module/module.prop` | Magisk module metadata |
| `chargectl/magisk-module/service.sh` | Magisk boot service script |

---

## Notable Patterns

**Platform Detection Pattern:**
`install.sh` uses a `detect_platform()` function that checks for:
- Termux (`$PREFIX` + `pkg` command)
- macOS (`uname == Darwin`)
- Linux (`apt-get` available)
- Fallback to manual install instructions

**Idempotent Installation:**
All install functions check if a package is already installed before attempting installation. Safe to re-run.

**Docker Analysis Environment:**
The Dockerfile creates a portable Linux environment with all tools pre-installed. Useful for analyzing any project with a consistent toolset without touching the host system.

**Magisk Boot Module:**
`chargectl/magisk-module/` provides a true boot-time start for the battery limiter daemon on rooted Android devices, independent of Termux.

---

## Dependencies Summary

**Key system dependencies:**
- `git` — Version control
- `zsh` — Shell with oh-my-zsh
- `tmux` — Terminal multiplexer with tpm
- `fzf` — Fuzzy finder
- `bat` — Cat replacement with syntax highlighting
- `ripgrep` — Fast search
- `starship` — Cross-shell prompt
- `carapace` — Shell completions
- `zoxide` — Smart directory navigation
- `helix` — Modal editor
- `neovim` — Modal editor
- `jq` — JSON processor
- `gh` — GitHub CLI
- `uv` — Python package manager

**Platform-specific:**
- macOS: Homebrew, Ghostty, AeroSpace
- Linux: apt, official installers for starship/carapace
- Termux: pkg, termux-api
- Windows: GlazeWM

---

## Analysis Notes

**Confidence:** High

Project structure is clear and well-documented. All key technologies identified. README provides comprehensive usage instructions.

**Potential gaps:**
- `.secret_sample` contents not analyzed (intentionally opaque)
- `start.bat` (Windows) not analyzed in detail
- `glazevm/config.yaml` not read (Windows-specific)

**Next steps for onboarding:**
1. Read `README.md` for full usage instructions
2. Run `./install.sh` to install packages on your platform
3. Run `./link_dotfiles.sh` from `~/dotfile` to symlink configs
4. Edit `~/.secret` with your actual secrets

---

*Generated by Banneker Cartographer. For questions about this analysis, review the scan logs or re-run `/banneker:document`.*
