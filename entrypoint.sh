#!/bin/bash
# dotfile entrypoint: make the container run as the host user WITHOUT rebuilding
# the image. Works on macOS and Ubuntu with any UID/GID.
#
# Runs as root (compose sets user "0:0"), remaps the `dev` user to the host
# UID/GID, re-owns the persistent home/caches, then drops privileges and execs
# the requested command. The image itself is always the same.
#
# UID/GID resolution:
#   1. $USER_ID / $GROUP_ID env vars if set, else
#   2. the owner of the mounted /workspace (the host's project dir), else
#   3. 1000.
set -euo pipefail

USERNAME=dev

TARGET_UID="${USER_ID:-$(stat -c %u /workspace 2>/dev/null || echo 1000)}"
TARGET_GID="${GROUP_ID:-$(stat -c %g /workspace 2>/dev/null || echo 1000)}"

if [[ "$(id -u)" == "0" ]]; then
    # Ensure a group with the target GID exists (allow GID collisions: some
    # hosts reuse e.g. 20). We only rely on the numeric GID afterwards.
    if ! getent group "$TARGET_GID" >/dev/null 2>&1; then
        groupadd -o -g "$TARGET_GID" "dotgid"
    fi
    # Remap `dev` to the target UID/GID (numeric match is what matters;
    # the group name stays `dev`/primary-group lookup is via the GID).
    if [[ "$(id -u "$USERNAME" 2>/dev/null)" != "$TARGET_UID" ]] || \
       [[ "$(id -g "$USERNAME" 2>/dev/null)" != "$TARGET_GID" ]]; then
        usermod -o -u "$TARGET_UID" -g "$TARGET_GID" -d "/home/$USERNAME" "$USERNAME"
    fi
    # Re-own the persistent home + caches (named volumes). /workspace is a host
    # bind mount and is left untouched.
    chown -R "$TARGET_UID:$TARGET_GID" "/home/$USERNAME" 2>/dev/null || true
fi

export HOME="/home/$USERNAME"
exec setpriv --reuid "$TARGET_UID" --regid "$TARGET_GID" --init-groups -- "$@"