/* SPDX-License-Identifier: ((GPL-2.0+ WITH Linux-syscall-note) OR MIT) */
/*
 * The few definitions the RK628 core needs from Rockchip's
 * include/uapi/linux/rk_hdmirx_config.h, which only exists in Rockchip BSP
 * kernels. Values match that header.
 *
 * Copyright (C) 2022 Rockchip Electronics Co., Ltd.
 * Trimmed for the rk628-pi module by Ground Plane Studio, LLC, 2026.
 */

#ifndef _RK628_PI_COMPAT_H
#define _RK628_PI_COMPAT_H

#include <drm/drm_mode.h>
#include <linux/types.h>

enum hdmirx_color_range {
	HDMIRX_DEFAULT_RANGE = 0,
	HDMIRX_LIMIT_RANGE = 1,
	HDMIRX_FULL_RANGE = 2,
};

enum hdmirx_color_space {
	HDMIRX_XVYCC601 = 0,
	HDMIRX_XVYCC709 = 1,
	HDMIRX_SYCC601 = 2,
	HDMIRX_ADOBE_YCC601 = 3,
	HDMIRX_ADOBE_RGB = 4,
	HDMIRX_BT2020_YCC_CONST_LUM = 5,
	HDMIRX_BT2020_RGB_OR_YCC = 6,
	HDMIRX_RGB = 7,
};

enum user_color_range {
	COLOR_RANGE_AUTO = 0,
	COLOR_RANGE_LIMIT = 1,
	COLOR_RANGE_FULL = 2,
};

#endif /* _RK628_PI_COMPAT_H */
