#!/system/bin/sh

RESUME=20
STOP=90
INTERVAL=120
CHG=/sys/class/power_supply/battery
LOG=/data/data/com.termux/files/home/chargectl.log

log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

while :; do
	CAP=$(cat "$CHG/capacity")
	if [ "$(cat /sys/class/power_supply/usb/online)" = "1" ]; then
		if [ "$CAP" -ge "$STOP" ] && [ "$(cat "$CHG/input_suspend")" != "1" ]; then
			echo 1 > "$CHG/input_suspend"
			log "stopped charging at ${CAP}%"
		elif [ "$CAP" -le "$RESUME" ] && [ "$(cat "$CHG/input_suspend")" != "0" ]; then
			echo 0 > "$CHG/input_suspend"
			log "resumed charging at ${CAP}%"
		fi
	fi
	sleep "$INTERVAL"
done
