#!/bin/bash
# PengCCIcons 一键编译脚本（需在 macOS + Theos + iOS 16 SDK 下运行）
# 作者：鹏gg
set -e

echo "==> [1/3] 编译主插件 (PengCCIcons.dylib)"
make clean || true
make package

echo "==> [2/3] 编译设置面板 (PengCCIconsPrefs)"
cd prefs
make clean || true
make package
cd ..

echo "==> [3/3] 汇总 .deb"
mkdir -p packages
# Theos 默认把产物放在 ./packages 或 .theos/_/ 下，统一收集
find . -name "*.deb" -not -path "*/.git/*" -exec cp -v {} packages/ \;

echo "完成。packages/ 下即为可安装的 deb："
ls -la packages/
