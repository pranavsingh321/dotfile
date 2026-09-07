#!/bin/bash
# dotfile entrypoint: make the container run as the host user WITHOUT rebuilding
# the image. Works on macOS and Ubuntu with any UID/GID.
#
# Runs as root (compose sets user "0:0"), remaps the `dev` user to the host
# UID/GID, re-owns the persistent home/caches, optionally syncs the container
# username/group with the host identity, then drops privileges and execs the
# requested command (defaults to /bin/bash). The image itself is always the same.
#
# UID/GID resolution:
#   1. $USER_ID / $GROUP_ID env vars if set, else
#   2. the owner of the mounted /workspace (the host's project dir), else
#   3. 1000.
#
# Username/group sync (optional):
#   $HOST_USERNAME / $HOST_GROUP rename the container user/group to match the
#   host (compose injects them from the host environment). Numeric UID/GID are
#   what actually matter for git/opencode/ssh; the name sync is so tools report
#   the same identity as on the host.
set -euo pipefail

USERNAME=dev
HOMEDIR="/home/$USERNAME"

TARGET_UID="${USER_ID:-$(stat -c %u /workspace 2>/dev/null || echo 1000)}"
TARGET_GID="${GROUP_ID:-$(stat -c %g /workspace 2>/dev/null || echo 1000)}"

HOST_USERNAME="${HOST_USERNAME:-${HOST_USER:-}}"
HOST_GROUP="${HOST_GROUP:-}"

if [[ "$(id -u)" == "0" ]]; then
    # Ensure a group with the target GID exists (allow GID collisions: some
    # hosts reuse e.g. 20). We only rely on the numeric GID afterwards.
    if ! getent group "$TARGET_GID" >/dev/null 2>&1; then
        groupadd -o -g "$TARGET_GID" "dotgid"
    fi
    # Current container username owning the target UID (fallback: `dev`).
    CUR_USER="$(getent passwd "$TARGET_UID" 2>/dev/null | cut -d: -f1 || true)"
    CUR_USER="${CUR_USER:-$USERNAME}"
    # Remap to the target UID/GID (numeric match is what matters; the group
    # name lookup is via the numeric GID).
    if [[ "$(id -u "$CUR_USER" 2>/dev/null)" != "$TARGET_UID" ]] || \
       [[ "$(id -g "$CUR_USER" 2>/dev/null)" != "$TARGET_GID" ]]; then
        usermod -o -u "$TARGET_UID" -g "$TARGET_GID" -d "$HOMEDIR" "$CUR_USER"
    fi
    # Optional: mirror the host username so `whoami`/git/opencode report the
    # host identity. The home dir path stays $HOMEDIR (compose mounts target
    # /home/dev), so only the passwd entry is renamed.
    if [[ -n "$HOST_USERNAME" && "$HOST_USERNAME" != "$CUR_USER" ]]; then
        usermod -l "$HOST_USERNAME" "$CUR_USER" 2>/dev/null \
            || echo "warn: want host username '$HOST_USERNAME', keeping '$CUR_USER'"
    fi
    # Optional: mirror the host group name (purely cosmetic).
    if [[ -n "$HOST_GROUP" ]]; then
        GNAME="$(getent group "$TARGET_GID" 2>/dev/null | cut -d: -f1 || true)"
        if [[ -n "$GNAME" && "$HOST_GROUP" != "$GNAME" ]]; then
            groupmod -n "$HOST_GROUP" "$GNAME" 2>/dev/null \
                || echo "warn: want host group '$HOST_GROUP', keeping '$GNAME'"
        fi
    fi
    # Re-own the persistent home + caches (named volumes). /workspace is a host
    # bind mount and is left untouched.
    chown -R "$TARGET_UID:$TARGET_GID" "$HOMEDIR" 2>/dev/null || true
fi

export HOME="$HOMEDIR"
exec setpriv --reuid "$TARGET_UID" --regid "$TARGET_GID" --init-groups -- "${@:-/bin/bash}"