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

# uv (installs to ~/.local/bin, already on PATH in .bashrc)
USER "$USERNAME"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

USER root
RUN chown -R "$USERNAME:$GID" /home/"$USERNAME"/helix \
    # Pre-create so the compose uv-cache volume inherits the right owner
    && mkdir -p "/home/$USERNAME/.cache/uv" \
    && chown -R "$USERNAME:$GID" "/home/$USERNAME/.cache" \
    # Mounted host dirs are owned by a different UID; stop git refusing to operate on them
    && git config --system --add safe.directory '*' \
    && mkdir -p /workspace && chown "$USERNAME:$GID" /workspace

# Default working dir: mount your project here (-v "$PWD":/workspace)
WORKDIR /workspace
USER "$USERNAME"

ENV SHELL=/bin/bash
CMD ["bash"]
