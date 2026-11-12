#!/bin/sh
# Remove the RK628 driver and overlay. Run with sudo, then reboot.
set -e

CONFIG=/boot/firmware/config.txt

if [ "$(id -u)" != 0 ]; then
	echo "Run with sudo."
	exit 1
fi

sed -i '/^dtoverlay=rk628/d' "$CONFIG"
rm -f /boot/firmware/overlays/rk628.dtbo
find /lib/modules -name 'rk628-pi.ko*' -delete
depmod -a

echo "Removed. camera_auto_detect is left as it is in $CONFIG."
echo "Reboot to finish."
