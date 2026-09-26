#!/bin/bash
# 修改 extracted/ 下的素材或 plist 后，重新打包成可安装的 deb
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
VER="0.0.13"
PKG_NAME="com.taoxi.ccmoudlebg_${VER}_iphoneos-arm64.deb"
OUT_DIR="$ROOT/deb"
PKG="$OUT_DIR/$PKG_NAME"

echo "==> 清理旧构建"
rm -rf "$ROOT/build"
mkdir -p "$ROOT/build/pkg" "$OUT_DIR"

echo "==> 复制文件树 (rootless: /var/jb/...)"
cp -R "$ROOT/extracted/var" "$ROOT/build/pkg/var"

echo "==> 写入 DEBIAN/control"
mkdir -p "$ROOT/build/pkg/DEBIAN"
cp "$ROOT/control" "$ROOT/build/pkg/DEBIAN/control"

echo "==> 打包 $PKG_NAME"
dpkg-deb -b -Zgzip "$ROOT/build/pkg" "$PKG"

echo "==> 完成: $PKG"
ls -la "$PKG"
