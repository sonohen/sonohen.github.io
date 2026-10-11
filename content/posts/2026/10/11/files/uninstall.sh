#!/bin/sh
set -eu
[ "$(id -u)" -eq 0 ] || { echo 'Run with sudo on the host.' >&2; exit 1; }
[ "$(ps -p 1 -o comm=)" = systemd ] || { echo 'Run on the systemd host.' >&2; exit 1; }
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Remove only files that still match this implementation.
for name in 90-nextdns-reconnect nextdns-reconnect.timer nextdns-reconnect.service; do
    case "$name" in
        90-*) target=/etc/NetworkManager/dispatcher.d/$name ;;
        *) target=/etc/systemd/system/$name ;;
    esac
    if [ -e "$target" ] || [ -L "$target" ]; then
        [ ! -L "$target" ] && cmp -s "$source_dir/$name" "$target" || { echo "Modified file; refusing removal: $target" >&2; exit 1; }
    fi
done
rm -f /etc/NetworkManager/dispatcher.d/90-nextdns-reconnect
systemctl stop nextdns-reconnect.timer nextdns-reconnect.service
rm -f /etc/systemd/system/nextdns-reconnect.timer /etc/systemd/system/nextdns-reconnect.service
systemctl daemon-reload
echo 'Removed. NextDNS configuration was preserved.'
