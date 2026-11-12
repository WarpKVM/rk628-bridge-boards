#!/bin/sh
# rk628-check.sh: find the RK628 bridge, show what the HDMI source is sending,
# and capture some frames to check the link.
#
#   sh rk628-check.sh            # 300 frames
#   sh rk628-check.sh 1000       # more frames
#   sh rk628-check.sh 30 frames.raw  # also save the frames (NV12, or UYVY on a Pi)
#
# Needs v4l-utils (v4l2-ctl). Run as a user in the video group, or with sudo.

FRAMES=${1:-300}
OUT=${2:-/dev/null}

find_dev() { # $1 = class glob, $2 = name to match
	for n in /sys/class/video4linux/$1/name; do
		if grep -q "$2" "$n" 2>/dev/null; then
			echo "/dev/$(basename "$(dirname "$n")")"
			return
		fi
	done
}

SUBDEV=$(find_dev 'v4l-subdev*' rk628)
VIDEO=$(find_dev 'video*' stream_cif_mipi_id0)	# Rockchip hosts
[ -z "$VIDEO" ] && VIDEO=$(find_dev 'video*' unicam-image)	# Raspberry Pi

if [ -z "$SUBDEV" ]; then
	echo "No RK628 found. Check the cable, and that the bridge was connected before power on."
	exit 1
fi
if [ -z "$VIDEO" ]; then
	echo "Found the RK628 at $SUBDEV, but no capture device (stream_cif_mipi_id0)."
	exit 1
fi
if [ ! -r "$SUBDEV" ] || [ ! -w "$VIDEO" ]; then
	echo "No access to $SUBDEV and $VIDEO. Run with sudo, or add yourself to the"
	echo "video group (sudo usermod -aG video \$USER) and log in again."
	exit 1
fi

# Lock to whatever the source is sending now.
v4l2-ctl -d "$SUBDEV" --set-dv-bt-timings query >/dev/null 2>&1
T=$(v4l2-ctl -d "$SUBDEV" --get-dv-timings)
W=$(echo "$T" | awk '/Active width/ {print $3}')
H=$(echo "$T" | awk '/Active height/ {print $3}')
FPS=$(echo "$T" | sed -n 's/.*(\([0-9.]*\) frames per second).*/\1/p')

echo "Bridge:  $SUBDEV"
echo "Capture: $VIDEO"
echo "Source:  ${W}x${H} at ${FPS} Hz"

if [ "$W" = 640 ] && [ "$H" = 480 ]; then
	echo "640x480 is what the driver reports with no signal. Check the HDMI source."
	exit 1
fi

# Set the format first, then stream. On the stock driver, a capture started
# while the source is still changing mode can stall: press Ctrl-C and rerun.
# Rockchip capture takes NV12; the Raspberry Pi takes packed UYVY.
PIX=NV12
v4l2-ctl -d "$VIDEO" --list-formats | grep -q "'NV12'" || PIX=UYVY
v4l2-ctl -d "$VIDEO" --set-fmt-video=width="$W",height="$H",pixelformat=$PIX || exit 1
echo "Capturing $FRAMES frames..."
# Allow twice the expected time plus 10 s, then give up rather than hang.
LIMIT=$(( FRAMES * 2 / ${FPS%%.*} + 10 ))
R=$(timeout "$LIMIT" v4l2-ctl -d "$VIDEO" --stream-mmap=4 --stream-count="$FRAMES" \
	--stream-to="$OUT" 2>&1 | tr '<' '\n' | grep fps | tail -1)
if [ -n "$R" ]; then
	echo "Measured: $(echo $R)"
else
	echo "No frames within $LIMIT s. If this mode needs more bandwidth than your"
	echo "link has (two-lane ports top out at 1080p60), pick a lower mode."
	exit 1
fi
