#!/bin/bash
# Build the Aura boot images in the release from source.
#
#   SDK=~/luckfox-aura-sdk ./build-boot-img.sh boot.img
#
# SDK       Luckfox's Aura SDK (luckfox_aura_v1.0.1_20260518). Its kernel at
#           commit b8187ea6c6dbd97deee68cfe121bedc66219262e (6.1.141) is the
#           base, and it provides the toolchain, mkimage and resource_tool.
# RKKERNEL  Rockchip's develop-6.1 kernel at 77168c8d5ab82399f65a80e9f807b50ba37cf483,
#           for the RK628 driver (default: fetched into ./rockchip-kernel).
# boot.img  Luckfox's own boot.img, from their image download. Its resource
#           section supplies the boot logos.
#
# Writes boot-rk628-22p.img and boot-rk628-2x22p.img to the current directory.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
HOSTS=$(dirname "$HERE")
STOCKBOOT=$(realpath "$1")
SDK=${SDK:?set SDK to the Luckfox Aura SDK}
K=$SDK/sysdrv/source/kernel
RKKERNEL=${RKKERNEL:-$PWD/rockchip-kernel}
OUT=$PWD

export ARCH=arm64
export CROSS_COMPILE=$SDK/tools/linux/toolchain/aarch64-rockchip1240-linux-gnu/bin/aarch64-rockchip1240-linux-gnu-
TK=$SDK/sysdrv/tools/pc/toolkits
if [ -x "$TK/lz4/lz4" ]; then PATH="$TK/lz4:$PATH"; elif [ -x "$TK/lz4" ]; then PATH="$TK:$PATH"; fi
MKIMAGE=$SDK/sysdrv/source/uboot/rkbin/tools/mkimage
RT=$K/scripts/resource_tool

# The RK628 driver: Rockchip's develop-6.1 copy with our fixes.
if [ ! -d "$RKKERNEL" ]; then
	git init -q "$RKKERNEL"
	git -C "$RKKERNEL" fetch -q --depth 1 https://github.com/rockchip-linux/kernel.git 77168c8d5ab82399f65a80e9f807b50ba37cf483
	git -C "$RKKERNEL" checkout -q FETCH_HEAD
	git -C "$RKKERNEL" apply "$HOSTS/firefly-rk3576/0001-rk628h-fixes.patch"
fi
rm -rf "$K/drivers/media/i2c/rk628"
cp -a "$RKKERNEL/drivers/media/i2c/rk628" "$K/drivers/media/i2c/rk628"
(cd "$K" && patch -p1 -s < "$HERE/0001-rk628-older-rkcif.patch")

# Device trees and config.
D=$K/arch/arm64/boot/dts/rockchip
cp "$HERE"/dts/*.dts "$HERE"/dts/*.dtsi "$D/"
for f in "$HERE"/dts/*.dts; do
	n=$(basename "${f%.dts}")
	grep -q "$n.dtb" "$D/Makefile" || echo "dtb-\$(CONFIG_CPU_RV1126B) += $n.dtb" >> "$D/Makefile"
done
cp "$HERE/config-6.1.141-rk628" "$K/.config"
make -C "$K" olddefconfig
make -C "$K" -j"$(nproc)" Image.lz4 dtbs

# Pack a FIT boot image like Luckfox's. On the Aura, U-Boot passes the kernel
# the DTB inside the resource section, so the new DTB goes there too.
pack() { # $1 = dts name, $2 = output
	W=$(mktemp -d)
	for n in fdt kernel resource; do
		pos=$(fdtget "$STOCKBOOT" /images/$n data-position)
		sz=$(fdtget "$STOCKBOOT" /images/$n data-size)
		dd if="$STOCKBOOT" of="$W/$n" bs=1M iflag=skip_bytes,count_bytes skip="$pos" count="$sz" status=none
	done
	cp "$K/arch/arm64/boot/Image.lz4" "$W/kernel"
	cp "$D/$1.dtb" "$W/fdt"
	mkdir "$W/res" && (cd "$W/res" && "$RT" --unpack --image="$W/resource" >/dev/null)
	cp "$D/$1.dtb" "$W/res/out/rk-kernel.dtb"
	(cd "$W/res/out" && "$RT" --pack --image="$W/resource" rk-kernel.dtb logo.bmp logo_kernel.bmp >/dev/null)
	cat > "$W/boot.its" <<'ITS'
/dts-v1/;
/ {
    description = "FIT image with Linux kernel, FDT blob and resource";
    images {
        fdt      { data = /incbin/("fdt");      type = "flat_dt"; arch = "arm64"; compression = "none"; load = <0xffffff00>; hash { algo = "sha256"; }; };
        kernel   { data = /incbin/("kernel");   type = "kernel";  arch = "arm64"; os = "linux"; compression = "lz4"; entry = <0xffffff01>; load = <0xffffff01>; hash { algo = "sha256"; }; };
        resource { data = /incbin/("resource"); type = "multi";   arch = "arm64"; compression = "none"; hash { algo = "sha256"; }; };
    };
    configurations { default = "conf";
        conf { rollback-index = <0x00>; fdt = "fdt"; kernel = "kernel"; multi = "resource";
            signature { algo = "sha256,rsa2048"; padding = "pss"; key-name-hint = "dev"; sign-images = "fdt", "kernel", "multi"; }; };
    };
};
ITS
	(cd "$W" && "$MKIMAGE" -f boot.its -E -p 0x800 boot.img >/dev/null)
	cp "$W/boot.img" "$OUT/$2"
	rm -rf "$W"
	echo "$2: $(stat -c%s "$OUT/$2") bytes"
}

pack rv1126b-luckfox-aura-rk628h-single boot-rk628-22p.img
pack rv1126b-luckfox-aura-rk628h-dual boot-rk628-2x22p.img
