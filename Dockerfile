# Dotfiles environment on Linux with Python 3.12 base.
# Build:  docker compose build
# Run:    docker compose run --rm dottools
# All tool/LSP/formatter installs are owned by install.sh (invoked via
# link_dotfiles.sh); the Dockerfile only wires up container plumbing.
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color

# --- Build-time configuration ---
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

# --- Base packages needed for install.sh / link_dotfiles.sh to run ---
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

# --- Dev user (passwordless sudo so install.sh's apt/pip/npm installs work) ---
RUN groupadd -g "$GID" "$USERNAME" \
    && useradd -m -s /bin/bash -u "$UID" -g "$GID" "$USERNAME" \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME" \
    && chmod 0440 "/etc/sudoers.d/$USERNAME"

# Put install.sh's targets on PATH (go toolchain + user bins) so steps like
# "go install gopls" work during the build. ${USERNAME} expands to the dev user.
ENV PATH="/usr/local/go/bin:/home/${USERNAME}/.local/bin:/home/${USERNAME}/go/bin:$PATH"

USER "$USERNAME"
WORKDIR "/home/$USERNAME"

# install.sh drops binaries here; pre-create so it is writable by the user.
RUN mkdir -p "$HOME/.local/bin" "$HOME/.config/helix"

# link_dotfiles.sh refuses to run from anywhere except ~/dotfile
COPY --chown="$USERNAME:$GID" . "/home/$USERNAME/dotfile"
WORKDIR "/home/$USERNAME/dotfile"

# Installs CLI tools, editor, and all LSP servers/formatters (install.sh), then links dotfiles.
RUN bash ./link_dotfiles.sh

USER root

# --- Container plumbing (config only, not tool installs) ---

# JAVA_HOME -> arch-independent symlink so it works on amd64 and arm64.
RUN ln -s "/usr/lib/jvm/java-21-openjdk-$(dpkg --print-architecture)" /usr/local/java

# Restore PATH on login; install.sh targets ~/.local/bin and ~/go/bin.
RUN printf 'export PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:$PATH"\n' \
        > /etc/profile.d/dotfiles-path.sh \
    && chmod 755 /etc/profile.d/dotfiles-path.sh
RUN chown -R "$USERNAME:$GID" /home/"$USERNAME"/helix \
    && mkdir -p "/home/$USERNAME/.cache/uv" \
    && chown -R "$USERNAME:$GID" "/home/$USERNAME/.cache" \
    && git config --system --add safe.directory '*' \
    && mkdir -p /workspace && chown "$USERNAME:$GID" /workspace

# Default working dir: mount your project here (-v "$PWD":/workspace)
WORKDIR /workspace
USER "$USERNAME"

ENV SHELL=/bin/bash \
    JAVA_HOME=/usr/local/java
CMD ["bash"]
