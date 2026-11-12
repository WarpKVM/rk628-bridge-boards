# Raspberry Pi: rk628-pi driver and overlay

Driver and device tree overlay for the rk628-22p on a Raspberry Pi CM4 (4 lanes
on CAM1) or a Pi 4B (2 lanes, through a 22-pin to 15-pin camera cable).
Tested on Raspberry Pi OS Lite (64-bit, Debian 13) with kernel 6.18.

## Install

On the Pi, with the bridge connected before power on:

```bash
sudo sh install.sh
sudo reboot
```

`install.sh` builds the driver against the running kernel's headers, installs
it and the overlay, turns off `camera_auto_detect`, and adds one
`dtoverlay=rk628` line to `/boot/firmware/config.txt` (keeping a backup next to
it). Arguments are added to that line:

| Option | Use it when |
|---|---|
| `2lane` | Two-lane port: Pi 4B, or CM4 CAM0. Tops out at 1080p60 |
| `int_gpio=<n>` | Connector pin 18 reaches SoC GPIO n (WarpKVM CM4 carrier: `int_gpio=26`). Without it the driver polls once a second |
| `reset_gpio=<n>` | Pin 17 reaches SoC GPIO n instead of the camera power line |
| `cam0` | Bridge on CAM0 instead of CAM1 (use with `2lane`) |
| `media-controller` | Use the media controller unicam driver instead of the legacy one |

Then check it with `sh ../rk628-check.sh`. Undo with `sudo sh uninstall.sh`.

If the build stops on missing headers: `sudo apt install linux-headers-rpi-v8`.

## Tested

| Mode | CM4, 4 lanes | 2 lanes |
|---|---|---|
| 3840x2160 @ 30 | 30.00 fps, 0 errors | Too fast |
| 1920x1080 @ 120 | 120.00 fps, 0 errors | Too fast |
| 1920x1080 @ 60 | 60.00 fps | 60.00 fps |

Two lanes carry at most about 1800 Mbps each, and 1080p120 or 4K30 in YUV 4:2:2
need about 2400. `rk628-check.sh` says so instead of hanging if you try.

Frames come out as UYVY. To save some: `sh ../rk628-check.sh 30 frames.uyvy`.

## How it fits together

- **Reset.** Pin 17 of a Pi camera connector is the camera power enable, and on
  the rk628-22p it is the RK628 reset. On a CM4 that pin is driven by the
  firmware GPIO expander, which the CM4 device tree also hands to a camera power
  regulator (`cam1_reg`). The overlay turns that regulator off and gives the pin
  to the driver, which otherwise sees the bridge held in reset.
- **Interrupt.** Pin 18 goes wherever your carrier sends it, so it is an option.
  Polling works fine without it.
- **Driver.** Rockchip's RK628 driver from their 6.1 BSP, with the same fixes as
  the Firefly and Aura kernels, and the Rockchip-only interfaces swapped for
  standard V4L2: DV timings, EDID, source change events, and a CSI-2 endpoint
  that unicam understands. One module, `rk628-pi.ko`.

## Files

| Path | What |
|---|---|
| `install.sh`, `uninstall.sh` | Install and remove |
| `driver/` | Module source and Makefile (`make`, `sudo make install`) |
| `overlay/rk628-overlay.dts` | Overlay source, built to `rk628.dtbo` by `install.sh` |

## Not tested yet

- HDMI audio over I2S on the Pi
- A real Pi 4B (the 2-lane numbers come from a CM4 limited to two lanes, which
  is the same chip and capture driver)
- Raspberry Pi 5, which has a different camera interface
