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

# --- Mount validation --------------------------------------------------------
# Every mount lands in the container at a fixed path regardless of the host; if
# the source is wrong/missing (e.g. binary not at OPENCODE_BIN, dir outside
# Docker's file sharing on macOS, ~-paths not expanded) the container still
# starts but the path is broken. Verify all of them up-front and print what to
# fix instead of failing cryptically later:
#
#   /workspace                      <- ${PROJECT_DIR:-~} (rw)
#   /host                           <- ${MOUNT_ROOT:-/} (ro)
#   /home/dev                       <- dotfiles-home volume (rw)
#   /home/dev/.cache/uv             <- uv-cache volume (rw)
#   /home/dev/.config/opencode      <- ${HOME}/.config/opencode (rw)
#   /home/dev/.local/share/opencode <- ${HOME}/.local/share/opencode (rw)
#   /usr/local/bin/opencode         <- ${OPENCODE_BIN:-~/.opencode/bin/opencode} (ro)
MOUNT_FAILED=0

check_mount() {
    local path="$1" kind="$2" want="$3" desc="$4" hint="$5"
    local problems=()

    if [[ ! -e "$path" ]]; then
        problems+=("missing (source likely did not exist or mount failed)")
    else
        { [[ "$kind" != "dir" || -d "$path" ]]; } || problems+=("not a directory")
        { [[ "$kind" != "file" || -f "$path" ]]; } || problems+=("not a regular file")
        { [[ "$want" != *r* || -r "$path" ]]; } || problems+=("not readable")
        { [[ "$want" != *x* || -x "$path" ]]; } || problems+=("not executable")
        if [[ "$want" == *w* && "$kind" == "dir" ]]; then
            if ! touch "$path/.dotfile-write-probe" 2>/dev/null; then
                problems+=("not writable")
            else
                rm -f "$path/.dotfile-write-probe" 2>/dev/null || true
            fi
        fi
        if [[ "$want" == *m* ]] && ! grep -Fq " $path " /proc/self/mounts 2>/dev/null; then
            problems+=("not an active mount (source may be outside Docker's file sharing)")
        fi
        if [[ "$want" == *n* ]] && [[ -z "$(find "$path" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
            printf '  [WARN] %-38s %-28s EMPTY: host source not shared/writable from the host?\n' "$path" "$desc"
            printf '         -> %s\n' "$hint"
        fi
    fi

    if (( ${#problems[@]} )); then
        MOUNT_FAILED=1
        printf '  [FAIL] %-38s %-28s %s\n' "$path" "$desc" "${problems[*]}"
        printf '         -> fix: %s\n' "$hint"
    else
        printf '  [ ok ] %-38s %s\n' "$path" "$desc"
    fi
}

echo "Verifying container mounts:"
check_mount /workspace                 dir  rwm "host project" \
    "export PROJECT_DIR=/path/to/repo then docker compose run"
check_mount /host                      dir  rm   "host root (ro)" \
    "set MOUNT_ROOT=/ (macOS: also add it in Docker Desktop Settings -> File sharing); use MOUNT_ROOT_MODE=rw only if you need writes"
check_mount /home/dev                  dir  rw   "dotfiles-home volume" \
    "named volume, no host path to fix"
check_mount /home/dev/.cache/uv        dir  rw   "uv-cache volume" \
    "named volume, no host path to fix"
check_mount /home/dev/.config/opencode dir  rwmn "opencode config" \
    "mkdir -p ~/.config/opencode (macOS: keep it under a shared dir)"
check_mount /home/dev/.local/share/opencode dir rw "opencode data" \
    "mkdir -p ~/.local/share/opencode (macOS: keep it under a shared dir)"
check_mount /usr/local/bin/opencode    file rxm  "opencode binary" \
    "OPENCODE_BIN=$(command -v opencode) docker compose run --rm dottools"

if (( MOUNT_FAILED )); then
    echo
    echo "ERROR: one or more mounts are misconfigured - fix the paths above, then re-run."
    exit 1
fi

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