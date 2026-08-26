#!/bin/bash
set -euo pipefail

# --- Detect platform -------------------------------------------------------

detect_platform() {
    if [[ -n "${PREFIX:-}" && -d "$PREFIX" ]] && command -v pkg >/dev/null 2>&1; then
        echo "termux"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "linux"
    else
        echo "unknown"
    fi
}

ensure_apt_available() {
    echo "Updating package lists..."
    sudo apt-get update
}

apt_install() {
    local pkg="$1"
    if command -v "$pkg" >/dev/null 2>&1; then
        echo "  $pkg already installed"
    else
        echo "  Installing $pkg..."
        sudo apt-get install -y "$pkg" || echo "  WARN: could not install $pkg via apt"
    fi
}

termux_install() {
    local pkg="$1"
    if command -v "$pkg" >/dev/null 2>&1; then
        echo "  $pkg already installed"
    else
        echo "  Installing $pkg..."
        pkg install -y "$pkg" || echo "  WARN: could not install $pkg via pkg"
    fi
}

brew_install() {
    local pkg="$1"
    if brew list "$pkg" >/dev/null 2>&1; then
        echo "  $pkg already installed"
    else
        echo "  Installing $pkg..."
        brew install "$pkg"
    fi
}

brew_cask_install() {
    local pkg="$1"
    if brew list --cask "$pkg" >/dev/null 2>&1; then
        echo "  $pkg already installed"
    else
        echo "  Installing $pkg (cask)..."
        brew install --cask "$pkg"
    fi
}

ensure_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "  oh-my-zsh already installed"
    else
        echo "  Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
}

ensure_zsh_autosuggestions() {
    local dest="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [[ -d "$dest" ]]; then
        echo "  zsh-autosuggestions already installed"
    else
        echo "  Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$dest"
    fi
}

ensure_tpm() {
    local dest="$HOME/.tmux/plugins/tpm"
    if [[ -d "$dest" ]]; then
        echo "  tpm already installed"
    else
        echo "  Installing tmux plugin manager (tpm)..."
        git clone https://github.com/tmux-plugins/tpm "$dest"
    fi
}

ensure_starship() {
    if command -v starship >/dev/null 2>&1; then
        echo "  starship already installed"
    else
        echo "  Installing starship via official installer..."
        curl -sS https://starship.rs/install.sh | sh || echo "  WARN: starship install failed"
    fi
}

ensure_carapace() {
    if command -v carapace >/dev/null 2>&1; then
        echo "  carapace already installed"
    elif command -v go >/dev/null 2>&1; then
        echo "  Installing carapace via go..."
        go install github.com/carapace-sh/carapace-bin@latest
    else
        echo "  WARN: carapace requires Go. Install Go and rerun, or install carapace manually."
    fi
}

ensure_python_tools() {
    if command -v pyright >/dev/null 2>&1 && command -v ruff >/dev/null 2>&1; then
        echo "  pyright and ruff already installed"
    else
        if command -v npm >/dev/null 2>&1; then
            echo "  Installing pyright via npm..."
            npm install -g pyright || echo "  WARN: could not install pyright via npm"
        elif command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
            echo "  Installing pyright and ruff via pip..."
            pip install pyright ruff || pip3 install pyright ruff || echo "  WARN: could not install pyright/ruff via pip"
        else
            echo "  WARN: neither npm nor pip found. Install pyright and ruff manually."
        fi
        if command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
            if ! command -v ruff >/dev/null 2>&1; then
                echo "  Installing ruff via pip..."
                pip install ruff || pip3 install ruff || echo "  WARN: could not install ruff via pip"
            fi
        fi
    fi
}

ensure_go() {
    if command -v go >/dev/null 2>&1; then
        echo "  Go already installed"
    else
        echo "  Installing Go..."
        local os arch
        case "$(uname -s)" in
            Darwin) os="darwin" ;;
            Linux)  os="linux" ;;
            *) echo "  WARN: unsupported OS for Go"; return ;;
        esac
        case "$(uname -m)" in
            x86_64)  arch="amd64" ;;
            aarch64|arm64) arch="arm64" ;;
            *) echo "  WARN: unsupported arch for Go"; return ;;
        esac
        curl -fsSL "https://go.dev/dl/go1.23.4.${os}-${arch}.tar.gz" | sudo tar -xz -C /usr/local || \
            echo "  WARN: Go install failed"
    fi
    if command -v go >/dev/null 2>&1 && ! command -v gopls >/dev/null 2>&1; then
        echo "  Installing gopls..."
        go install golang.org/x/tools/gopls@latest || echo "  WARN: could not install gopls"
    fi
}

ensure_rust() {
    if command -v rustup >/dev/null 2>&1; then
        echo "  Rust already installed"
    else
        echo "  Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || \
            echo "  WARN: Rust install failed"
        . "$HOME/.cargo/env" 2>/dev/null || true
    fi
    if command -v rustup >/dev/null 2>&1 && ! rustup component list --installed 2>/dev/null | grep -q rust-analyzer; then
        echo "  Installing rust-analyzer..."
        rustup component add rust-analyzer || echo "  WARN: could not install rust-analyzer"
    fi
}

ensure_java() {
    if command -v java >/dev/null 2>&1; then
        echo "  Java already installed"
    else
        echo "  Installing Java JDK..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y openjdk-21-jdk-headless || echo "  WARN: could not install JDK via apt"
        elif command -v brew >/dev/null 2>&1; then
            brew install openjdk@21 || echo "  WARN: could not install JDK via brew"
        elif [[ -n "${PREFIX:-}" ]]; then
            pkg install openjdk-21 || echo "  WARN: could not install JDK via pkg"
        else
            echo "  WARN: no package manager found. Install JDK 17 manually."
        fi
    fi
    if command -v java >/dev/null 2>&1 && ! command -v jdtls >/dev/null 2>&1; then
        echo "  Installing Eclipse JDT Language Server..."
        local jdtls_dir="$HOME/.local/jdtls"
        mkdir -p "$jdtls_dir"
        curl -fsSL "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-1.54.0-202511211032.tar.gz" | \
            tar -xzf - -C "$jdtls_dir" || echo "  WARN: could not download jdtls"
        if [[ -f "$jdtls_dir/bin/jdtls" ]]; then
            chmod +x "$jdtls_dir/bin/jdtls"
            mkdir -p "$HOME/.local/bin"
            ln -sf "$jdtls_dir/bin/jdtls" "$HOME/.local/bin/jdtls"
            echo "  jdtls installed to $jdtls_dir"
        fi
    fi
}

# --- macOS -----------------------------------------------------------------

install_macos() {
    echo "==> Installing packages via Homebrew"

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    local formulas=(git zsh fzf bat ripgrep starship carapace zoxide tmux helix neovim jq)
    for pkg in "${formulas[@]}"; do
        brew_install "$pkg"
    done

    echo "==> Installing casks"
    brew_cask_install ghostty

    echo "==> Installing aerospace (tap)"
    brew tap nikitabobko/tap 2>/dev/null || true
    brew_cask_install nikitabobko/tap/aerospace

    echo "==> Installing shell/editor extras"
    ensure_oh_my_zsh
    ensure_zsh_autosuggestions
    ensure_tpm
    ensure_go
    ensure_rust
    ensure_java
    ensure_python_tools
}

# --- Linux (apt) -----------------------------------------------------------

install_linux() {
    echo "==> Installing packages via apt"

    ensure_apt_available

    local packages=(git zsh fzf bat ripgrep tmux neovim helix starship carapace tmux gh uv zoxide jq zoxide)
    for pkg in "${packages[@]}"; do
        apt_install "$pkg"
    done

    local packages_optional=(starship helix)
    for pkg in "${packages_optional[@]}"; do
        apt_install "$pkg"
    done

    echo "==> Installing shell/editor extras"
    ensure_oh_my_zsh
    ensure_zsh_autosuggestions
    ensure_tpm
    ensure_starship
    ensure_carapace
    ensure_go
    ensure_rust
    ensure_java
    ensure_python_tools
}

# --- Termux ----------------------------------------------------------------

install_termux() {
    echo "==> Installing packages via pkg"

    pkg update
    pkg upgrade -y

    local packages=(git fzf ripgrep bat tmux jq zoxide starship helix carapace python tmux gh uv cronie golang termux-api)
    for pkg in "${packages[@]}"; do
        termux_install "$pkg"
    done

    echo "==> Installing shell/editor extras"
    ensure_tpm
    ensure_go
    ensure_rust
    ensure_java
    ensure_python_tools
}

# --- Main ------------------------------------------------------------------

PLATFORM=$(detect_platform)

case "$PLATFORM" in
    macos)  install_macos ;;
    linux)  install_linux ;;
    termux) install_termux ;;
    *)
        echo "Error: unsupported platform. Install the following manually:" >&2
        echo "  git, zsh, oh-my-zsh, fzf, bat, ripgrep, starship, carapace, zoxide," >&2
        echo "  tmux (+tpm), helix, neovim, jq" >&2
        echo "  macOS only: ghostty, aerospace" >&2
        exit 1
        ;;
esac

echo "Package installation complete."
