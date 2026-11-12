#!/bin/sh
# Put the factory kernel back. Run with sudo, then reboot.
set -e

STORE=/usr/lib/rk628-kernel

if [ "$(id -u)" != 0 ]; then
	echo "Run with sudo."
	exit 1
fi
if [ ! -f "$STORE/Image-6.1.84.stock" ]; then
	echo "No saved factory kernel in $STORE. Nothing to undo."
	exit 1
fi

cp "$STORE/Image-6.1.84.stock" /boot/Image-6.1.84
for l in /boot/lib/modules/*; do
	[ -L "$l" ] && case "$(readlink "$l")" in "$STORE"/*) rm "$l" ;; esac
done
sync
fsfreeze -f /boot && fsfreeze -u /boot

echo "Factory kernel restored. Reboot to use it."
