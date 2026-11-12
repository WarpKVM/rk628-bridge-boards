#!/bin/sh
# Build and install the RK628 driver and overlay on a Raspberry Pi CM4 running
# Raspberry Pi OS. Run from this folder:
#
#   sudo sh install.sh                 # bridge on CAM1, four lanes
#   sudo sh install.sh int_gpio=26     # plus the interrupt pin (WarpKVM carrier)
#
# Any arguments are added to the dtoverlay=rk628 line. Undo with:
#   sudo sh uninstall.sh
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
CONFIG=/boot/firmware/config.txt
KVER=$(uname -r)

if [ "$(id -u)" != 0 ]; then
	echo "Run with sudo."
	exit 1
fi
if [ ! -d "/lib/modules/$KVER/build" ]; then
	echo "Kernel headers for $KVER are missing. Install them with:"
	echo "  sudo apt install linux-headers-rpi-v8"
	exit 1
fi

echo "Building the driver for $KVER..."
make -s -C "$HERE/driver" clean
make -s -C "$HERE/driver" -j"$(nproc)"
make -s -C "$HERE/driver" install

echo "Installing the overlay..."
dtc -q -@ -I dts -O dtb -o /boot/firmware/overlays/rk628.dtbo "$HERE/overlay/rk628-overlay.dts"

# camera_auto_detect would load camera drivers on the same port, so turn it
# off, and keep exactly one rk628 line.
cp "$CONFIG" "$CONFIG.before-rk628"
sed -i -e 's/^camera_auto_detect=1/camera_auto_detect=0/' -e '/^dtoverlay=rk628/d' "$CONFIG"
LINE="dtoverlay=rk628"
for a in "$@"; do LINE="$LINE,$a"; done
printf '\n[all]\n%s\n' "$LINE" >>"$CONFIG"

echo "Added '$LINE' to $CONFIG (backup: $CONFIG.before-rk628)."
echo "Reboot to load it."
