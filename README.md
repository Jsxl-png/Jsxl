# 控制中心图标替换 · PengCCIcons

> 控制中心模块图标 / 视频 / GIF 替换插件，**支持 iOS 16**，**rootless** 越狱。
> 作者：**鹏gg**

## 功能
- **总开关**：一键启用/停用整个插件。
- **逐模块开关**：WiFi、蓝牙、飞行、蜂窝、隔空投送、旋转锁、勿扰、低电量、手电筒、计算器、相机，每个模块可单独开启自定义图标。
- **从相册选择素材**：每个模块点「从相册选择」即可选 **图片 / 视频 / GIF**，自动导出到本地供插件加载。
  - 静态图 → 替换控制中心按钮的 glyph 图标。
  - 视频 / GIF → 在按钮上叠加播放层（AspectFill）。
- 设置改动实时通知 SpringBoard 刷新控制中心。

## 工程结构
```
PengCCIcons/
├── Makefile                 # Theos 编译配置（rootless, iOS 16）
├── control                  # deb 包信息（作者 鹏gg）
├── PengCCIcons.plist        # tweak 注入 filter（SpringBoard）
├── Tweak.xm                 # 主逻辑：读设置 + 替换图标 + 视频/GIF 叠加
├── prefs/                   # 设置面板（PreferenceBundle）
│   ├── Info.plist
│   ├── PengCCIconsPrefs.h/.m   # 相册选择器 + 素材导出
│   └── Resources/Root.plist    # 总开关 + 11 个模块开关 + 相册按钮
└── layout/Library/PreferenceLoader/Preferences/   # 设置入口
```

## 编译（需在 macOS 上）
本环境（Linux 沙箱）没有 iOS SDK / 工具链，**无法在此编译出 .deb**。
请在装有 Theos + iOS 16 SDK 的 macOS 上执行：

```bash
# 1) 编译主插件
make package
# 2) 编译设置面板
cd prefs && make package && cd ..
# 3) 安装到越狱设备（需配置 THEOS_DEVICE_IP/PORT）
make install
```

依赖：`ellekit`、`preferenceloader`，iOS 16.0+。

## 使用
1. 越狱设备上通过 Sileo/Zebra 安装编译好的 deb，或 `make install`。
2. 打开 **设置 → 控制中心图标替换**。
3. 打开「启用插件」总开关。
4. 对需要自定义的模块：打开该模块开关 → 点「从相册选择」挑一张图/视频/GIF。
5. 上滑控制中心即可看到效果（必要时 Respring）。

## 已知可调点（真机适配）
- **模块类名**：`Tweak.xm` 的 `ModuleKeyForObject` 用类名映射设置键。iOS 16 小版本若某模块不生效，用 FLEX 抓到真实类名后补充到 `ModuleMap()` 即可。
- **图标尺寸**：控制中心 glyph 约 22~28pt，建议素材做成透明背景的方形 PNG。
- **视频/GIF 叠加**：依赖 `CCUIButton -layoutSubviews` 钩子；若叠加层位置偏移，按真机按钮 frame 微调 `PengMediaLayer`。
