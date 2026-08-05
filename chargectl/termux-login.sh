#!/data/data/com.termux/files/usr/bin/sh

CT='^sh /data/data/com.termux/files/home/chargectl.sh$'

su -c "if ! pgrep -f '$CT' >/dev/null 2>&1; then setsid sh /data/data/com.termux/files/home/chargectl.sh </dev/null >/dev/null 2>&1 & fi"
