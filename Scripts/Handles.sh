#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

FEEDS_PATH="./feeds"
PACKAGE_PATH="./package"

#修补命令统一入口：FIX <名称> <守卫目录> <命令...>
#守卫目录不存在时直接跳过，保证在 bash -e 下不中断
FIX() {
	local NAME=$1
	local GUARD=$2
	shift 2

	[ -d "$GUARD" ] || return 0

	echo " "
	if "$@"; then
		echo "$NAME has been fixed!"
	else
		echo "$NAME fix failed; continuing!"
	fi
}

#修改argon主题字体和颜色
FIX "theme-argon" "$PACKAGE_PATH/luci-theme-argon" sed -i \
	"s/primary '.*'/primary '#31a1a1'/g; s/'0.2'/'0.5'/g; s/'none'/'bing'/g; s/'600'/'normal'/g" \
	"$PACKAGE_PATH/luci-theme-argon/luci-app-argon-config/root/etc/config/argon"

#修改aurora菜单式样
FIX "theme-aurora" "$PACKAGE_PATH/luci-app-aurora-config" find \
	"$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora/" -type f -name '*.template' -exec sed -i \
	"s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +

#修改vantage进度条标签字体（anothaDev/luci-theme-vantage#52）
FIX "theme-vantage" "$PACKAGE_PATH/luci-theme-vantage" sed -i \
	-e '/^\/\* progress bars: thin track/,$ { /^\.cbi-progressbar::before {/,/^}/ { s/^[[:space:]]*font: 500 var(--fs-micro)\/1\.2 var(--mono);/\tfont: inherit; line-height: normal;/; } }' \
	"$PACKAGE_PATH/luci-theme-vantage/luci-theme-vantage/htdocs/luci-static/vantage/vantage.css"

#修改mini-diskmanager菜单位置
FIX "mini-diskmanager" "$PACKAGE_PATH/luci-app-mini-diskmanager" sed -i "s/services/system/g" \
	"$PACKAGE_PATH/luci-app-mini-diskmanager/luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json"

#修改natmapt菜单位置
FIX "natmapt" "$PACKAGE_PATH/luci-app-natmapt" sed -i "s/network/services/g" \
	"$PACKAGE_PATH/luci-app-natmapt/root/usr/share/luci/menu.d/luci-app-natmap.json"
# 强制开启 Overlayfs 内核高级特性，完美修复 Docker 挂载 invalid argument 错误
echo "CONFIG_OVERLAY_FS_REDIRECT_DIR=y" >> target/linux/generic/config-5.15
echo "CONFIG_OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW=y" >> target/linux/generic/config-5.15
echo "CONFIG_OVERLAY_FS_INDEX=y" >> target/linux/generic/config-5.15

# 顺便兼容 6.1 和 6.6 内核版本
echo "CONFIG_OVERLAY_FS_REDIRECT_DIR=y" >> target/linux/generic/config-6.1
echo "CONFIG_OVERLAY_FS_INDEX=y" >> target/linux/generic/config-6.1
echo "CONFIG_OVERLAY_FS_REDIRECT_DIR=y" >> target/linux/generic/config-6.6
echo "CONFIG_OVERLAY_FS_INDEX=y" >> target/linux/generic/config-6.6

# 自动将默认 Rootfs (Overlay) 分区大小修改为 30GB（针对京东云赵云的 64G/128G eMMC 极其安全且管够）
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=30720" >> .config

# 云编译时直接清空并禁用官方不稳定的 snapshots 核心自定义软件源，彻底根除 apk update 报错
sed -i 's/option check_signature/# option check_signature/g' package/base-files/files/etc/apk/repositories 2>/dev/null || sed -i '/src\/gz/d' package/base-files/files/etc/apk/repositories
echo "" > package/base-files/files/etc/apk/repositories


