#!/bin/sh
# Install the patched RK628 kernel on a Firefly ROC-RK3576-PC running the
# factory Ubuntu 22.04 image. Run from the unpacked release folder:
#
#   sudo sh install.sh
#
# Undo with: sudo sh uninstall.sh
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
KVER=$(cat "$HERE/KERNEL_VERSION")
STORE=/usr/lib/rk628-kernel

if [ "$(id -u)" != 0 ]; then
	echo "Run with sudo."
	exit 1
fi
if ! tr -d '\0' </proc/device-tree/model | grep -q ROC-RK3576-PC; then
	echo "This kernel is for the Firefly ROC-RK3576-PC only."
	exit 1
fi
if [ ! -f /boot/Image-6.1.84 ]; then
	echo "/boot/Image-6.1.84 not found. This expects the factory 6.1.84 image."
	exit 1
fi

mkdir -p "$STORE"

# Keep the factory kernel, once. A second run must not overwrite it with ours.
if [ ! -f "$STORE/Image-6.1.84.stock" ]; then
	cp /boot/Image-6.1.84 "$STORE/Image-6.1.84.stock"
	echo "Saved the factory kernel to $STORE/Image-6.1.84.stock"
fi

# The factory boot entry loads /boot/Image-6.1.84, so the new kernel takes
# that file name. /boot is a 128 MB partition with no room for both kernels.
cp "$HERE/Image" /boot/Image-6.1.84

# Modules live on the root filesystem, since /boot is nearly full. The
# factory image links /lib/modules into /boot/lib/modules, so a symlink there
# is all the kernel needs to find them.
rm -rf "$STORE/modules/$KVER"
mkdir -p "$STORE/modules"
cp -a "$HERE/modules/$KVER" "$STORE/modules/"
ln -sfn "$STORE/modules/$KVER" "/boot/lib/modules/$KVER"
depmod "$KVER"

# U-Boot reads /boot without replaying the ext4 journal, so make sure the new
# kernel is written out in full before the next boot.
sync
fsfreeze -f /boot && fsfreeze -u /boot

echo "Installed kernel $KVER. Reboot to use it."
