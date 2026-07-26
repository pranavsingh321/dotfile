#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
pkill crond 2>/dev/null
rm -f ~/.termux/crond.pid 2>/dev/null
crond
