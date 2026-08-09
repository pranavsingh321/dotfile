#!/system/bin/sh

CT=/data/data/com.termux/files/home/chargectl.sh

i=0
while [ ! -r /sys/class/power_supply/battery/capacity ] && [ "$i" -lt 30 ]; do
	sleep 1
	i=$((i + 1))
done

# /data may be encrypted at boot; wait for the Termux home to be decrypted
# (the daemon file appears there once it is) before giving up.
i=0
while [ ! -f "$CT" ] && [ "$i" -lt 720 ]; do
	sleep 5
	i=$((i + 5))
done

if [ -f "$CT" ] && ! pgrep -f "$CT" >/dev/null 2>&1; then
	setsid sh "$CT" </dev/null >/dev/null 2>&1 &
fi
