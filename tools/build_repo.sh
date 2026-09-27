#!/usr/bin/env bash
# build_repo.sh —— 在源仓库根目录运行，重新生成 APT 源索引
# 用法: 把新的 .deb 放进 debs/ 后，执行 ./tools/build_repo.sh
set -e
cd "$(dirname "$0")/.."

if [ ! -d debs ]; then echo "错误：当前目录没有 debs/"; exit 1; fi

echo "=== 1) 重新扫描 debs/ 生成 Packages ==="
dpkg-scanpackages -m debs /dev/null > Packages 2>/dev/null || dpkg-scanpackages debs > Packages

echo "=== 2) 生成 Packages.gz ==="
gzip -kf Packages

echo "=== 3) 重建 Release ==="
python3 - <<'PY'
import hashlib
def sums(fn):
    b = open(fn, "rb").read()
    return hashlib.md5(b).hexdigest(), hashlib.sha256(b).hexdigest(), len(b)
mp, sp, zp = sums("Packages")
mg, sg, zg = sums("Packages.gz")
open("Release", "w", encoding="utf-8").write(f"""Origin: PengGG
Label: 鹏gg 插件源
Suite: stable
Version: 1.0
Codename: ios
Architectures: iphoneos-arm iphoneos-arm64
Components: main
Description: 鹏gg 的越狱插件源 (iOS 16)
MD5Sum:
 {mp} {zp} Packages
 {mg} {zg} Packages.gz
SHA256:
 {sp} {zp} Packages
 {sg} {zg} Packages.gz
""")
print("  Release 已更新")
PY

echo "=== 完成：Packages / Packages.gz / Release 已重建 ==="
echo "把 debs/、Packages、Packages.gz、Release 一起 push 到仓库 main 分支即可。"
