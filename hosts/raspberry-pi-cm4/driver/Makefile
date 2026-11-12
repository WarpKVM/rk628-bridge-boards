# SPDX-License-Identifier: GPL-2.0
#
# rk628-pi: Rockchip RK628 HDMI to MIPI CSI-2 bridge, out-of-tree module for
# Raspberry Pi kernels. On the Pi itself:
#
#   sudo apt install linux-headers-rpi-v8
#   make
#   sudo make install
#
# Cross build: make KDIR=/path/to/prepared/kernel ARCH=arm64 \
#              CROSS_COMPILE=aarch64-linux-gnu-

obj-m := rk628-pi.o
rk628-pi-y := rk628.o rk628_cru.o rk628_hdmirx.o rk628_dsi.o \
	      rk628_combrxphy.o rk628_combtxphy.o rk628_mipi_dphy.o \
	      rk628_post_process.o rk628_csi_pi.o

KDIR ?= /lib/modules/$(shell uname -r)/build

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules

# Copy the module ourselves: the kernel's modules_install warns about a
# missing System.map on Raspberry Pi OS, which ships headers without it.
KVER ?= $(shell uname -r)

install:
	install -D -m 644 rk628-pi.ko /lib/modules/$(KVER)/updates/rk628-pi.ko
	rm -f /lib/modules/$(KVER)/updates/rk628-pi.ko.xz
	depmod -a $(KVER)

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean

.PHONY: all install clean
