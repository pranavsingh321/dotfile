# xrdp TLS: Cannot read private key file (Permission denied)

**Host:** thinkstationpgx-0d67  **Distro:** Ubuntu 24.04

## Symptom

RDP sessions still work, but TLS is unavailable and the session falls back to
unencrypted `RDP` security. `journalctl -u xrdp` shows:

```
xrdp[46199]: [ERROR] Cannot read private key file /etc/xrdp/key.pem: Permission denied
xrdp[46199]: [WARN ] Cannot accept TLS connections because certificate or private key file is not readable.
xrdp[46199]: [INFO ] Security protocol: configured [RDP], requested [SSL|HYBRID|HYBRID_EX|RDP], selected [RDP]
```

## How TLS loads its keys

- `/etc/xrdp/cert.pem` and `/etc/xrdp/key.pem` are **symlinks** to the Debian
  "snakeoil" files:
  - `cert.pem -> /etc/ssl/certs/ssl-cert-snakeoil.pem`
  - `key.pem  -> /etc/ssl/private/ssl-cert-snakeoil.key`
- The `xrdp` daemon runs as user `xrdp` (`User=xrdp`, `Group=xrdp` in
  `/usr/lib/systemd/system/xrdp.service`).
- So xrdp must be able to open `/etc/ssl/private/ssl-cert-snakeoil.key`,
  which requires:
  1. execute (`--x`) on the directory `/etc/ssl/private` (710 root:ssl-cert), and
  2. read permission on the key file itself (normally 640 root:ssl-cert).

## Debug steps

```bash
# 1. Confirm the error in the log
sudo journalctl -u xrdp -n 40 --no-pager

# 2. Confirm the user xrdp runs as, and its groups
ps aux | grep [x]rdp
id xrdp
# requires: xrdp uid/gid and membership in the ssl-cert group

# 3. Check the directory the key lives in
ls -la /etc/ssl/private | head
stat -c '%U:%G %a %n' /etc/ssl/private

# 4. Check the real key file permissions (not just the symlink)
sudo stat -c '%U:%G %a %n' /etc/ssl/private/ssl-cert-snakeoil.key
# Expected: 640 and group ssl-cert  -> xrdp can read it
# Broken  : 600 root:root           -> Permission denied

# 5. Simulate the read as the xrdp user (finds the failure directly)
sudo -u xrdp test -r /etc/ssl/private/ssl-cert-snakeoil.key \
  && echo "OK: xrdp can read key" \
  || echo "FAIL: xrdp cannot read key"

# 6. Confirm the symlinks are intact
ls -la /etc/xrdp/cert.pem /etc/xrdp/key.pem
```

## Fix

Two options. The dedicated-cert fix is recommended because it does not depend
on the system snakeoil key's group membership.

### Option A (recommended): dedicated cert/key owned by xrdp

```bash
# 1. Remove the snakeoil symlinks (do NOT write through them!)
sudo rm /etc/xrdp/key.pem /etc/xrdp/cert.pem

# 2. Generate a dedicated cert + key for xrdp
sudo openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout /etc/xrdp/key.pem -out /etc/xrdp/cert.pem \
  -subj "/CN=thinkstationpgx-0d67"

# 3. Make it readable by the xrdp user
sudo chown root:xrdp /etc/xrdp/key.pem /etc/xrdp/cert.pem
sudo chmod 640 /etc/xrdp/key.pem /etc/xrdp/cert.pem

# 4. Restart and verify
sudo systemctl restart xrdp
sudo journalctl -u xrdp -n 20 --no-pager
```

### Option B: repair the snakeoil key permissions

Only needed if you want to keep using the symlinked system key.

```bash
# Restore group ownership + read for ssl-cert group (xrdp is a member)
sudo chgrp ssl-cert /etc/ssl/private/ssl-cert-snakeoil.key
sudo chmod 640 /etc/ssl/private/ssl-cert-snakeoil.key

# Ensure the xrdp user is in the ssl-cert group
sudo usermod -aG ssl-cert xrdp

# Restart and verify
sudo systemctl restart xrdp
sudo journalctl -u xrdp -n 20 --no-pager
```

## Verification

- The log should no longer contain `Permission denied` or the
  `Cannot accept TLS connections` warning.
- Log in over RDP; the log should now show `SSL`/`HYBRID` selected instead of
  a fallback to `RDP`.

---

# Issue 2: Client session closes right after login

## Symptom

TLS/SSL now negotiates fine (`selected [SSL]`, `TLS connection established ... TLSv1.3`),
but the desktop session drops seconds after login. The RDP client disconnects
and shows a black/closed session.

`journalctl -u xrdp-sesman` shows the root cause:

```
xrdp-sesman[50168]: [INFO ] Session in progress on display 10, waiting until the window manager (pid 50170) exits to end the session
xrdp-sesman[50168]: [WARN ] Window manager (pid 50170, display 10) exited with non-zero exit code 1 and signal 0. This could indicate a window manager config problem
xrdp-sesman[50168]: [WARN ] Window manager (pid 50170, display 10) exited quickly (0 secs). This could indicate a window manager config problem
```

When the window manager exits, xrdp-sesman tears down the X server and the
session, which closes the client's connection.

## Root cause

The default session manager is GNOME (`/usr/bin/gnome-session`). The user
already has an **active local GNOME console session** on display `:1`:

```
loginctl list-sessions    # session 2 = pinnacle on seat0, STATE active
who                        # pinnacle :1
```

GNOME only allows one session manager per user. The second (xrdp) GNOME
instance sees the one already running and quits immediately:

```
journalctl --user --no-pager | grep gnome-session
gnome-session-binary[51076]: WARNING: Session manager already running!
```

## Debug steps

```bash
# 1. Confirm the window manager exit in the sesman log
sudo journalctl -u xrdp-sesman -n 20 --no-pager

# 2. Confirm a local console session is holding GNOME
loginctl list-sessions
who

# 3. Confirm the session manager refuses to start a second time
journalctl --user --no-pager | grep -i "session manager already running"

# 4. Verify Xorg itself is fine (not the cause)
grep -iE "error|fail|abort|fatal" ~/.xorgxrdp.10.log
# Expected: few (EE) logind/drm lines that are harmless; server exits 0
```

## Fix (option 1, no extra software): run a second GNOME in a private bus

Requires no new packages. Start GNOME inside its own D-Bus session so it does
not see the already-running session manager (per-user check). This works even
if the same user is also logged into the local console.

### 1. Create `~/.xsession` (picked up by xrdp's `/etc/X11/Xsession`)

```bash
cat > ~/.xsession <<'EOF'
#!/bin/sh
# ~/.xsession - starts GNOME in a private D-Bus bus for xrdp
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
exec dbus-run-session -- gnome-session --session=ubuntu
EOF
chmod +x ~/.xsession
```

### 2. Restart and reconnect

```bash
sudo systemctl restart xrdp-sesman
```

Reconnect over RDP; you should land in GNOME.

## Fix (option 2): give the xrdp session a lighter desktop (XFCE)

Requires installing a new desktop. Only needed if you want to avoid GNOME's
other RDP quirks (software rendering, DRI3/GLES warnings, occasional blank
screen). The local GNOME console session stays untouched.

```bash
sudo apt update && sudo apt install -y xfce4 xfce4-goodies

cat > ~/.xsession <<'EOF'
#!/bin/sh
# ~/.xsession - used by xrdp /etc/X11/Xsession to pick the desktop
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_DESKTOP=xubuntu
export XDG_CURRENT_DESKTOP=XFCE
exec dbus-launch --exit-with-session startxfce4
EOF
chmod +x ~/.xsession

sudo systemctl restart xrdp-sesman
```

## Verification

- `journalctl -u xrdp-sesman -n 20` shows NO `Window manager ... exited quickly`
  warning while you are connected.
- The desktop stays up; the RDP client no longer disconnects.

## Notes

- `~/.xsession` is read per user; remove it (or point it at XFCE) to pick a
  different desktop. With no `~/.xsession`, RDP runs the default GNOME session
  (which then conflicts if that same user holds the local console).
- To revert to plain GNOME: `rm ~/.xsession`.
- After the fix, re-verify the `~/.xorgxrdp.<display>.log` shows the server
  exiting only when you intentionally disconnect.

---

# Issue 3: Multi-user RDP access

## Design

xrdp authenticates through PAM against real Linux accounts: **one RDP
connector = one Unix user**. Each person needs their own account (username,
password, home dir). No per-user xrdp config is required; the box already logs:

```
xrdp-sesman: Terminal Server Users group is disabled, allowing authentication
```

so any valid Unix user can log in over RDP.

## Multi-user + the Issue 2 conflict

The "session manager already running" crash is **per user** (checked on the
per-user D-Bus `/run/user/<uid>/bus`). Consequences:

- A user with **no local console session** can use plain GNOME over RDP with
  no `~/.xsession` and no extra software.
- A user who logs into the local console **and** RDP at the same time hits the
  conflict -> that user needs a `~/.xsession` (GNOME private bus, option 1,
  no install needed).
- Each user's XFCE/GNOME desktop settings live in their own home dir and do
  not interfere.

With one account never used from console + RDP simultaneously, **no XFCE
install is needed**.

## Setup steps (users: ferri, pranav, sergei)

All three are given the private-bus `~/.xsession` and sudo membership (all
sudoers).

```bash
# 1. Create each user (prompts for password; full name optional; skip extra groups)
for u in ferri pranav sergei; do
  sudo adduser "$u"
done

# 2. Give each the GNOME private-bus .xsession so RDP works even if they
#    also hold the local console (no XFCE install):
for u in ferri pranav sergei; do
  sudo bash -c 'cat > "/home/'$u'/.xsession" <<EOF
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
exec dbus-run-session -- gnome-session --session=ubuntu
EOF'
  sudo chown "$u":"$u" /home/"$u"/.xsession
done

# 3. Make all three sudoers
for u in ferri pranav sergei; do
  sudo usermod -aG sudo "$u"
done

# 4. Spot-check each session lands in a desktop
sudo journalctl -u xrdp-sesman -n 20 --no-pager | grep -c "exited quickly"
# 0 = good
```

Watch the `adduser` prompts: you'll be asked for a password plus a few
defaults (real name blank is fine, just press Enter). `adduser` already
creates the home dir and login shell. If a user already exists, `adduser`
aborts — check first with `id ferri && id pranav && id sergei`.

## Verification

- `loginctl list-sessions` shows one active session per connected user
  (plus pinnacle's local console on `:1`).
- Each user connects over RDP and gets a desktop that stays up.
- `xrdp-sesman` assigns separate displays (e.g. `:10`, `:11`, ...) per session
  automatically.

## Notes

- Deleting a user and their data: `sudo deluser --remove-home <name>`
- The 2880x1800 RDP resolution cap is a client setting, not per-user.
- All sessions share one `xrdp` daemon; `sudo systemctl restart xrdp` does not
  kick individual logged-in sessions (only `xrdp-sesman` teardown affects
  them).