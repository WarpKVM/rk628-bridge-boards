# Host support

| Path | What |
|---|---|
| [`rk628-check.sh`](rk628-check.sh) | Finds the bridge, shows the source mode and checks capture. Works on every host here |
| [`edid/`](edid/) | EDIDs for 1080p60, 1080p120, 1080p144, 4K30 and 4K60, plus a tool to make your own |
| [`firefly-rk3576/`](firefly-rk3576/) | Firefly ROC-RK3576-PC (rk628-30p): driver patch, kernel config, installer |
| [`luckfox-aura/`](luckfox-aura/) | Luckfox Aura (rk628-22p, rk628-2x22p): device trees, boot image installer and build script |
| [`raspberry-pi-cm4/`](raspberry-pi-cm4/) | Raspberry Pi CM4 and Pi 4B (rk628-22p): driver, overlay, installer |

Install steps are in each board's README. The kernel patches, drivers and
device trees are GPL-2.0 (device trees GPL-2.0+ OR MIT), modified from
Rockchip's BSP kernel. The RK628 driver is not in mainline Linux.

## Kernel builds and source

The release kernels are built from:

| Host | Base | Our changes |
|---|---|---|
| Firefly ROC-RK3576-PC | Rockchip `develop-6.1` at `77168c8d5ab82399f65a80e9f807b50ba37cf483` (6.1.172) | `firefly-rk3576/0001-rk628h-fixes.patch`, config `firefly-rk3576/config-6.1.172-rk628` |
| Luckfox Aura | Luckfox Aura SDK v1.0.1 kernel at `b8187ea6c6dbd97deee68cfe121bedc66219262e` (6.1.141) | The Firefly kernel's RK628 driver plus `luckfox-aura/0001-rk628-older-rkcif.patch`, the device trees in `luckfox-aura/dts/`, config `luckfox-aura/config-6.1.141-rk628` |

The full kernel source for each release kernel is attached to the release next
to the binaries. `luckfox-aura/build-boot-img.sh` rebuilds the Aura boot images.

## Luckfox Aura

- `dts/rv1126b-luckfox-aura-rk628h-single.dts`: one 4-lane link (rk628-22p)
- `dts/rv1126b-luckfox-aura-rk628h-dual.dts` and `rv1126b-rk628h-dual.dtsi`:
  dual link for 4K60 (rk628-2x22p)
- `install.sh`: writes a boot image to the boot partition, SD card or eMMC
- `aura-live-dt-excerpt.dts`: the nodes as read from a running board, for reference
