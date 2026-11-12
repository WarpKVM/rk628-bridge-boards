#!/bin/sh
# Write an RK628 boot image to a Luckfox Aura running Luckfox's Debian 13 image
# (SD card or eMMC). Run from the unpacked release folder:
#
#   sudo sh install.sh rk628-22p      # one 22-pin link (rk628-22p)
#   sudo sh install.sh rk628-2x22p    # two links, 4K60 (rk628-2x22p)
#
# Then power the board off and on again. To undo, write Luckfox's own
# boot.img back the same way: sudo sh install.sh /path/to/boot.img
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
IMG=$1
case "$IMG" in
	rk628-22p|rk628-2x22p) IMG="$HERE/boot-$IMG.img" ;;
esac

if [ "$(id -u)" != 0 ]; then
	echo "Run with sudo."
	exit 1
fi
if [ -z "$1" ] || [ ! -f "$IMG" ]; then
	echo "Usage: sudo sh install.sh rk628-22p | rk628-2x22p | /path/to/boot.img"
	exit 1
fi
if ! tr -d '\0' </proc/device-tree/model | grep -q "Luckfox Aura"; then
	echo "This is for the Luckfox Aura only."
	exit 1
fi

# The root filesystem is on the same card as the boot partition, which is
# partition 4 on both the SD and eMMC images.
ROOT=$(sed -n 's/.*root=\(\/dev\/mmcblk[0-9]\)p[0-9]*.*/\1/p' /proc/cmdline)
BOOT=${ROOT}p4
if [ -z "$ROOT" ] || [ ! -b "$BOOT" ]; then
	echo "Could not find the boot partition (root= in /proc/cmdline)."
	exit 1
fi

# The boot partition holds a FIT image. Refuse to write over anything else.
MAGIC=$(dd if="$BOOT" bs=4 count=1 status=none | od -An -tx1 | tr -d ' ')
if [ "$MAGIC" != d00dfeed ]; then
	echo "$BOOT does not look like a boot partition. Stopping."
	exit 1
fi
SIZE=$(stat -c%s "$IMG")
if [ "$SIZE" -gt "$(blockdev --getsize64 "$BOOT")" ]; then
	echo "$IMG is larger than $BOOT."
	exit 1
fi

BACKUP=/root/boot-backup-$(date +%Y%m%d-%H%M%S).img
dd if="$BOOT" of="$BACKUP" bs=1M status=none
echo "Saved the current boot partition to $BACKUP"

dd if="$IMG" of="$BOOT" bs=1M conv=fsync status=none
sync
WANT=$(sha256sum <"$IMG" | cut -d' ' -f1)
GOT=$(dd if="$BOOT" bs=1M status=none | head -c "$SIZE" | sha256sum | cut -d' ' -f1)
if [ "$WANT" != "$GOT" ]; then
	echo "Read-back does not match. Restore with: sudo sh install.sh $BACKUP"
	exit 1
fi

echo "Done. Power the board off and on again (unplug it; do not use reboot)."
