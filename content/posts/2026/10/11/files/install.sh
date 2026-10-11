#!/bin/sh
set -eu
[ "$(id -u)" -eq 0 ] || { echo 'Run with sudo on the host.' >&2; exit 1; }
[ "$(ps -p 1 -o comm=)" = systemd ] || { echo 'Run on the systemd host, not inside Codex isolation.' >&2; exit 1; }
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Refuse to overwrite existing administrator configuration.
for target in /etc/NetworkManager/dispatcher.d/90-nextdns-reconnect /etc/systemd/system/nextdns-reconnect.timer /etc/systemd/system/nextdns-reconnect.service; do
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Already exists: $target" >&2; exit 1
    fi
done
systemctl cat nextdns.service >/dev/null
systemd-analyze verify "$source_dir/nextdns-reconnect.timer" "$source_dir/nextdns-reconnect.service"
install -o root -g root -m 0644 "$source_dir/nextdns-reconnect.service" /etc/systemd/system/nextdns-reconnect.service
install -o root -g root -m 0644 "$source_dir/nextdns-reconnect.timer" /etc/systemd/system/nextdns-reconnect.timer
systemctl daemon-reload
# Install dispatcher last: it becomes effective immediately, without NM restart.
install -o root -g root -m 0755 "$source_dir/90-nextdns-reconnect" /etc/NetworkManager/dispatcher.d/90-nextdns-reconnect
echo 'Installed. Next connection activation schedules restart after 5 seconds.'
