# 控制中心图标/背景替换 (CCMoudleBG)

> 为 iOS 16 控制中心**每个模块独立设置图片 / GIF / 视频背景**的越狱插件，并支持模块级视频静音。
> 本仓库提供**可直接安装的 deb 包**与**解包后的完整文件树**，方便你替换素材后自行重打包。

## 功能

- 控制中心各模块（WiFi、蓝牙、飞行、蜂窝、手电、计算器等）单独设置背景
- 背景支持 **图片 / GIF / 视频** 三种形式
- 支持模块级视频静音开关
- 带设置面板（设置 → CCMoudleBG），可逐项开关

## 支持环境

| 项目 | 说明 |
|------|------|
| 系统 | iOS **16.0 – 16.x**（控制文件限制 `firmware (>= 16.0)` 且 `<< 17.0`）|
| 越狱 | 无根（rootless）环境，如 Dopamine 等 |
| 架构 | `iphoneos-arm64` |
| 依赖 | `mobilesubstrate`(或 ellekit 兼容层)、`preferenceloader` |

> 注：原版依赖写的是 `mobilesubstrate`。在纯 rootless 越狱上，若安装后不生效，请确认已安装 ElleKit（它提供 substrate 兼容层）。

## 安装

方式一（推荐）：把 `deb/` 目录下的 `.deb` 用 Sileo / Zebra / Filza 安装，或用命令行：

```bash
dpkg -i deb/com.taoxi.ccmoudlebg_0.0.13_iphoneos-arm64.deb
killall SpringBoard   # 或 respring
```

方式二：本仓库即为源码/资源工程，可克隆后在本机修改素材、重打包（见下）。

## 项目结构

```
.
├── README.md
├── deb/
│   └── com.taoxi.ccmoudlebg_0.0.13_iphoneos-arm64.deb   # 可直接安装的包
├── extracted/                                               # deb 解包后的完整文件树
│   └── var/jb/Library/...                                   # dylib / 设置面板 / 图标
├── control                                                  # Debian 控制文件
└── build.sh                                                 # 修改素材后重打包脚本
```

关键文件说明：

| 路径 | 作用 |
|------|------|
| `extracted/var/jb/Library/MobileSubstrate/DynamicLibraries/CCMoudleBG.dylib` | 插件二进制（arm64e） |
| `extracted/var/jb/Library/MobileSubstrate/DynamicLibraries/CCMoudleBG.plist` | 注入过滤（SpringBoard） |
| `extracted/var/jb/Library/PreferenceBundles/CCMoudleBGPrefs.bundle/` | 设置面板 |
| `extracted/var/jb/Library/PreferenceLoader/Preferences/CCMoudleBGPrefs.plist` | 设置入口 |

## 自定义 / 重打包

1. 修改 `extracted/var/jb/Library/...` 下的素材或 plist。
2. 运行：

```bash
bash build.sh
```

会在当前目录生成新的 `.deb`，可再次安装到设备。

## 设置

安装后在 **设置 → CCMoudleBG** 中：
- 总开关与各模块独立开关
- 为每个模块指定图片 / GIF / 视频背景
- 模块级视频静音

## 来源与署名

- 原版插件：**CCMoudleBG** by **Taoxi**
- 原项目主页：<https://github.com/22556565/CCMoudleBG>
- 本仓库仅作整理与托管，便于在 iOS 16 无根环境下安装与二次修改。如需修改源码请从原作者仓库获取。
