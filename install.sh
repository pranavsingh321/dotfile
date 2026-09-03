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

# Run a command as root when needed (no-op if already root, or no sudo present).
maybe_sudo() {
    if [[ "$(id -u)" == "0" ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        "$@"
    fi
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
        mkdir -p "$HOME/.local/bin"
        curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin" || \
            echo "  WARN: starship install failed"
    fi
}

ensure_carapace() {
    if command -v carapace >/dev/null 2>&1; then
        echo "  carapace already installed"
        return
    fi
    echo "  Installing carapace (prebuilt binary)..."
    mkdir -p "$HOME/.local/bin"
    local cp_os=linux cp_arch=amd64
    case "$(uname -s)" in
        Darwin) cp_os=darwin ;;
    esac
    case "$(uname -m)" in
        aarch64|arm64) cp_arch=arm64 ;;
    esac
    local cp_ver=1.7.3
    curl -fsSL "https://github.com/carapace-sh/carapace-bin/releases/download/v${cp_ver}/carapace-bin_${cp_ver}_${cp_os}_${cp_arch}.tar.gz" \
        -o /tmp/carapace.tar.gz \
        && tar -xzf /tmp/carapace.tar.gz -C "$HOME/.local/bin" carapace \
        && chmod +x "$HOME/.local/bin/carapace" \
        && rm -f /tmp/carapace.tar.gz \
        || echo "  WARN: could not install carapace"
}

ensure_python_tools() {
    if command -v pyright >/dev/null 2>&1 && command -v ruff >/dev/null 2>&1; then
        echo "  pyright and ruff already installed"
    else
        if command -v npm >/dev/null 2>&1; then
            echo "  Installing pyright via npm..."
            maybe_sudo npm install -g pyright || echo "  WARN: could not install pyright via npm"
        elif command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
            echo "  Installing pyright and ruff via pip..."
            maybe_sudo pip install pyright ruff || maybe_sudo pip3 install pyright ruff || echo "  WARN: could not install pyright/ruff via pip"
        else
            echo "  WARN: neither npm nor pip found. Install pyright and ruff manually."
        fi
        if command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
            if ! command -v ruff >/dev/null 2>&1; then
                echo "  Installing ruff via pip..."
                maybe_sudo pip install ruff || maybe_sudo pip3 install ruff || echo "  WARN: could not install ruff via pip"
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
    if command -v rust-analyzer >/dev/null 2>&1; then
        echo "  rust-analyzer already installed"
        return
    fi
    echo "  Installing rust-analyzer (prebuilt binary, no rustup)..."
    local ra_arch=x86_64-unknown-linux-gnu
    case "$(uname -m)" in
        aarch64) ra_arch=aarch64-unknown-linux-gnu ;;
    esac
    local ra_tag=2026-08-24
    mkdir -p "$HOME/.local/bin"
    curl -fsSL "https://github.com/rust-lang/rust-analyzer/releases/download/${ra_tag}/rust-analyzer-${ra_arch}.gz" \
        -o /tmp/rust-analyzer.gz \
        && gunzip -c /tmp/rust-analyzer.gz > "$HOME/.local/bin/rust-analyzer" \
        && chmod +x "$HOME/.local/bin/rust-analyzer" \
        && rm -f /tmp/rust-analyzer.gz \
        || echo "  WARN: could not install rust-analyzer"
}

ensure_java() {
    if command -v java >/dev/null 2>&1; then
        echo "  Java already installed"
    else
        echo "  Installing Java JDK..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -qq
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

ensure_helix() {
    if command -v hx >/dev/null 2>&1 && hx --version 2>/dev/null | grep -q "25.01.1"; then
        echo "  helix 25.01.1 already installed"
        return
    fi
    echo "  Installing helix 25.01.1 (GitHub release)..."
    local hx_arch
    case "$(uname -m)" in
        x86_64)  hx_arch=x86_64-linux ;;
        aarch64|arm64) hx_arch=aarch64-linux ;;
        *) echo "  WARN: unsupported arch for helix"; return ;;
    esac
    local hx_tag=25.01.1
    curl -fsSL "https://github.com/helix-editor/helix/releases/download/${hx_tag}/helix-${hx_tag}-${hx_arch}.tar.xz" -o /tmp/hx.tar.xz || { echo "  WARN: could not download helix"; return; }
    maybe_sudo mkdir -p /opt/helix || return
    mkdir -p "$HOME/helix"
    maybe_sudo tar -xJf /tmp/hx.tar.xz -C /opt/helix --strip-components=1 || { echo "  WARN: could not extract helix"; return; }
    maybe_sudo ln -sf /opt/helix/hx /usr/local/bin/hx
    cp -r /opt/helix/runtime "$HOME/helix/runtime" || true
    rm -f /tmp/hx.tar.xz
}

ensure_node() {
    if command -v node >/dev/null 2>&1 && [[ "$(node -v | tr -d 'v' | cut -d. -f1)" -ge 22 ]]; then
        echo "  Node $(node -v) already installed"
        return
    fi
    echo "  Installing Node.js 22 (nodesource)..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | maybe_sudo bash - || {
        echo "  WARN: could not add nodesource repo"; return; }
    maybe_sudo apt-get install -y --no-install-recommends nodejs || \
        echo "  WARN: could not install nodejs via apt"
    maybe_sudo rm -rf /var/lib/apt/lists/*
}

ensure_marksman() {
    if command -v marksman >/dev/null 2>&1; then
        echo "  marksman already installed"
        return
    fi
    echo "  Installing marksman (markdown LSP, prebuilt binary)..."
    local mm_arch=x64
    case "$(uname -m)" in
        aarch64|arm64) mm_arch=arm64 ;;
    esac
    local mm_tag=2026-02-08
    curl -fsSL "https://github.com/artempyanykh/marksman/releases/download/${mm_tag}/marksman-linux-${mm_arch}" \
        -o "$HOME/.local/bin/marksman" \
        && chmod +x "$HOME/.local/bin/marksman" \
        || echo "  WARN: could not install marksman"
}

ensure_web_lsp() {
    echo "  Installing web LSP tools (typescript-language-server, vscode-html/css/json, prettier)..."
    mkdir -p "$HOME/.local/bin"
    maybe_sudo npm install -g \
        typescript-language-server \
        vscode-langservers-extracted \
        prettier \
        bash-language-server || echo "  WARN: could not install web LSP tools via npm"
}

ensure_bash_tools() {
    ensure_web_lsp
    if command -v shfmt >/dev/null 2>&1; then
        echo "  shfmt already installed"
    elif command -v go >/dev/null 2>&1; then
        echo "  Installing shfmt (bash formatter) via go..."
        go install mvdan.cc/sh/v3/cmd/shfmt@latest || \
            echo "  WARN: could not install shfmt"
    else
        echo "  WARN: shfmt requires Go. Install it manually."
    fi
}

# --- macOS -----------------------------------------------------------------

install_macos() {
    echo "==> Installing packages via Homebrew"

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    local formulas=(git fzf bat ripgrep starship carapace zoxide tmux helix neovim jq)
    for pkg in "${formulas[@]}"; do
        brew_install "$pkg"
    done

    echo "==> Installing casks"
    brew_cask_install ghostty

    echo "==> Installing aerospace (tap)"
    brew tap nikitabobko/tap 2>/dev/null || true
    brew_cask_install nikitabobko/tap/aerospace

    echo "==> Installing shell/editor extras"
    ensure_tpm
    ensure_go
    ensure_rust
    ensure_java
    ensure_python_tools
    ensure_marksman
    ensure_bash_tools
}

# --- Linux (apt) -----------------------------------------------------------

install_linux() {
    echo "==> Installing packages via apt"

    ensure_apt_available

    local packages=(git openssh-client fzf bat ripgrep tmux neovim carapace gh uv zoxide jq ncurses-term)
    for pkg in "${packages[@]}"; do
        apt_install "$pkg"
    done

    echo "==> Installing shell/editor extras"
    ensure_tpm
    ensure_helix
    ensure_node
    ensure_starship
    ensure_go
    ensure_carapace
    ensure_rust
    ensure_java
    ensure_python_tools
    ensure_marksman
    ensure_bash_tools
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
        echo "  git, fzf, bat, ripgrep, starship, carapace, zoxide," >&2
        echo "  tmux (+tpm), helix, neovim, jq" >&2
        echo "  macOS only: ghostty, aerospace" >&2
        exit 1
        ;;
esac

echo "Package installation complete."
