# PengCCIcons — 控制中心图标/视频/GIF 替换插件 (iOS 16, rootless)
# 作者：鹏gg
ARCHS = arm64
TARGET = iphone:16.0:16.0

# rootless：安装根映射到 /var/jb
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PengCCIcons
PengCCIcons_FILES = Tweak.xm
PengCCIcons_FRAMEWORKS = UIKit Photos AVFoundation ImageIO MobileCoreServices
PengCCIcons_PRIVATE_FRAMEWORKS = ControlCenterUI ControlCenterServices
PengCCIcons_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

# 设置面板（PreferenceBundle）
BUNDLE_NAME = PengCCIconsPrefs
PengCCIconsPrefs_OBJC_FILES = prefs/PengCCIconsPrefs.m
PengCCIconsPrefs_FRAMES = UIKit Photos AVFoundation
PengCCIconsPrefs_PRIVATE_FRAMEWORKS = Preferences
PengCCIconsPrefs_INSTALL_PATH = /Library/PreferenceBundles
PengCCIconsPrefs_PUBLIC_HEADERS =
PengCCIconsPrefs_CFLAGS = -fobjc-arc
PengCCIconsPrefs_LDFLAGS = -F/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard" || true
