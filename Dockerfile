# Dotfiles environment on Linux with Python 3.12 base.
# Build:  docker compose build
# Run:    docker compose run --rm dottools
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color

# Base tools required by install.sh / link_dotfiles.sh (sudo, curl for installers)
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        curl \
        git \
        ca-certificates \
        locales \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# UTF-8 locale (expected by .zshrc)
RUN sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

ARG USERNAME=dev
ARG UID=1000
ARG GID=1000
RUN groupadd -g "$GID" "$USERNAME" \
    && useradd -m -s /bin/bash -u "$UID" -g "$GID" "$USERNAME" \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME" \
    && chmod 0440 "/etc/sudoers.d/$USERNAME"

USER "$USERNAME"
WORKDIR "/home/$USERNAME"

# link_dotfiles.sh refuses to run from anywhere except ~/dotfile
COPY --chown="$USERNAME:$GID" . "/home/$USERNAME/dotfile"
WORKDIR "/home/$USERNAME/dotfile"

# Installs packages (linux/apt path) and links all dotfiles into ~
RUN bash ./link_dotfiles.sh

# Fill gaps left by apt (bookworm/trixie repos lack these): helix via official GitHub release
USER root
RUN set -eux; \
    hx_arch=; \
    case "$(uname -m)" in \
        x86_64)  hx_arch=x86_64-linux ;; \
        aarch64) hx_arch=aarch64-linux ;; \
    esac; \
    hx_tag="$(curl -fsSL https://api.github.com/repos/helix-editor/helix/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')"; \
    curl -fsSL "https://github.com/helix-editor/helix/releases/download/${hx_tag}/helix-${hx_tag}-${hx_arch}.tar.xz" -o /tmp/hx.tar.xz; \
    mkdir -p /opt/helix /home/"$USERNAME"/helix; \
    tar -xJf /tmp/hx.tar.xz -C /opt/helix --strip-components=1; \
    ln -sf /opt/helix/hx /usr/local/bin/hx; \
    cp -r /opt/helix/runtime /home/"$USERNAME"/helix/runtime; \
    rm -f /tmp/hx.tar.xz

# carapace (.bashrc sources it unconditionally)
RUN set -eux; \
    c_ver="$(curl -fsSL https://api.github.com/repos/carapace-sh/carapace-bin/releases/latest | grep -oP '"tag_name":\s*"\Kv[^"]+' | tr -d v)"; \
    c_arch=amd64; \
    case "$(uname -m)" in \
        aarch64|arm64) c_arch=arm64 ;; \
    esac; \
    curl -fsSL "https://github.com/carapace-sh/carapace-bin/releases/download/v${c_ver}/carapace-bin_${c_ver}_linux_${c_arch}.deb" -o /tmp/carapace.deb; \
    dpkg -i /tmp/carapace.deb; \
    rm -f /tmp/carapace.deb

# Node.js (for pyright LSP)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Java JDK + Eclipse JDT Language Server (jdtls) for Java LSP
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-21-jdk-headless \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-1.54.0-202511211032.tar.gz" -o /tmp/jdtls.tar.gz \
    && mkdir -p /opt/jdtls \
    && tar -xzf /tmp/jdtls.tar.gz --no-same-owner -C /opt/jdtls \
    && rm -f /tmp/jdtls.tar.gz

# Go toolchain
RUN set -eux; \
    go_arch=amd64; \
    case "$(uname -m)" in \
        aarch64|arm64) go_arch=arm64 ;; \
    esac; \
    curl -fsSL "https://go.dev/dl/go1.23.4.linux-${go_arch}.tar.gz" | tar -xz -C /usr/local

# gopls (must run as user so it installs to ~/go/bin)
USER "$USERNAME"
RUN export PATH="/usr/local/go/bin:$PATH" \
    && go install golang.org/x/tools/gopls@latest

# Rust toolchain + rust-analyzer
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . "$HOME/.cargo/env" \
    && rustup component add rust-analyzer

# Python LSP servers (pyright, ruff)
USER root
RUN npm install -g pyright \
    && pip install --no-cache-dir ruff

# uv (installs to ~/.local/bin, already on PATH in .bashrc)
USER "$USERNAME"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

USER root
RUN chown -R "$USERNAME:$GID" /home/"$USERNAME"/helix \
    && chown -R "$USERNAME:$GID" /home/"$USERNAME"/.cargo \
    && chown -R "$USERNAME:$GID" /home/"$USERNAME"/.rustup \
    # Pre-create so the compose uv-cache volume inherits the right owner
    && mkdir -p "/home/$USERNAME/.cache/uv" \
    && chown -R "$USERNAME:$GID" "/home/$USERNAME/.cache" \
    # Mounted host dirs are owned by a different UID; stop git refusing to operate on them
    && git config --system --add safe.directory '*' \
    && mkdir -p /workspace && chown "$USERNAME:$GID" /workspace

# Default working dir: mount your project here (-v "$PWD":/workspace)
WORKDIR /workspace
USER "$USERNAME"

ENV SHELL=/bin/bash \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    PATH="/opt/jdtls/bin:/home/$USERNAME/.cargo/bin:/usr/local/go/bin:/home/$USERNAME/go/bin:$PATH"
CMD ["bash"]
