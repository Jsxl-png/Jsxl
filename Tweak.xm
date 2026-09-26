// PengCCIcons — 控制中心图标/视频/GIF 替换
// 作者：鹏gg  |  支持 iOS 16  |  rootless
//
// 实现思路：
//  1) 设置项用 CFPreferences 跨进程读取（设置面板写入，SpringBoard 读取）。
//  2) 每个模块有：总开关 Enabled + 各模块开关 + 素材路径(从相册导出到本地)。
//  3) 静态图片：hook CCUIButtonModule -glyphImage 直接返回自定义图。
//  4) 视频/GIF：在模块按钮上叠加子层（AVPlayerLayer / 动画 UIImageView）。
//
// 注意：iOS 16 控制中心类名/ivar 可能因小版本不同略有差异，
//       若某模块不生效，用 FLEX 抓取真实类名后改 ModuleKeyForClass 即可。

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>

static NSString *const kPrefsID   = @"com.peng.ccicons";
static NSString *const kAssetsDir = @"/var/mobile/Library/Preferences/com.peng.ccicons/Assets";

#pragma mark - 设置读取

static id PrefValue(NSString *key) {
    CFStringRef app = (__bridge CFStringRef)kPrefsID;
    CFPropertyListRef v = CFPreferencesCopyAppValue((__bridge CFStringRef)key, app);
    if (!v) return nil;
    id obj = (__bridge_transfer id)v;
    return obj;
}

static BOOL BoolPref(NSString *key, BOOL def) {
    id v = PrefValue(key);
    if (v == nil) return def;
    if ([v isKindOfClass:[NSNumber class]]) return [v boolValue];
    if ([v isKindOfClass:[NSString class]]) return [v boolValue];
    return def;
}

static BOOL MasterEnabled(void) { return BoolPref(@"Enabled", NO); }

// 模块是否启用自定义图标
static BOOL ModuleEnabled(NSString *mod) {
    if (!MasterEnabled()) return NO;
    return BoolPref([NSString stringWithFormat:@"Module_%@_Enabled", mod], NO);
}

// 该模块素材类型：image / gif / video
static NSString *ModuleMediaType(NSString *mod) {
    return PrefValue([NSString stringWithFormat:@"Module_%@_Type", mod]) ?: @"image";
}

// 素材本地路径（相册导出后存放）
static NSString *AssetPathForModule(NSString *mod) {
    NSString *name = PrefValue([NSString stringWithFormat:@"Module_%@_Asset", mod]);
    if (!name) return nil;
    return [kAssetsDir stringByAppendingPathComponent:name];
}

#pragma mark - 模块类名 -> 设置键 映射

static NSDictionary<NSString *, NSString *> *ModuleMap(void) {
    static NSDictionary *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        m = @{
            @"WiFiModule":            @"wifi",
            @"BluetoothModule":       @"bluetooth",
            @"AirplaneModeModule":    @"airplane",
            @"CellularDataModule":    @"cellular",
            @"AirDropModule":         @"airdrop",
            @"RotationLockModule":    @"rotation",
            @"DNDModule":             @"dnd",
            @"DoNotDisturbModule":    @"dnd",
            @"LowPowerModeModule":    @"lowpower",
            @"FlashlightModule":      @"flashlight",
            @"CalculatorModule":      @"calculator",
            @"CAMPrivacyModule":      @"camera",
            @"CameraModule":          @"camera",
        };
    });
    return m;
}

static NSString *ModuleKeyForObject(id obj) {
    NSString *cls = NSStringFromClass([obj class]);
    return [ModuleMap() objectForKey:cls];
}

#pragma mark - 素材加载

// 静态图
static UIImage *LoadImage(NSString *path) {
    if (!path) return nil;
    return [UIImage imageWithContentsOfFile:path];
}

// GIF -> 动画 UIImage
static UIImage *LoadGIF(NSString *path) {
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return nil;
    CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!src) return nil;
    size_t count = CGImageSourceGetCount(src);
    if (count == 0) { CFRelease(src); return nil; }
    NSMutableArray *imgs = [NSMutableArray array];
    NSTimeInterval total = 0;
    for (size_t i = 0; i < count; i++) {
        CGImageRef cg = CGImageSourceCreateImageAtIndex(src, i, NULL);
        if (!cg) continue;
        [imgs addObject:[UIImage imageWithCGImage:cg]];
        CFRelease(cg);
        CFDictionaryRef props = CGImageSourceCopyPropertiesAtIndex(src, i, NULL);
        if (props) {
            CFDictionaryRef gif = CFDictionaryGetValue(props, kCGImagePropertyGIFDictionary);
            if (gif) {
                NSNumber *d = CFDictionaryGetValue(gif, kCGImagePropertyGIFUnclampedDelayTime);
                if (!d) d = CFDictionaryGetValue(gif, kCGImagePropertyGIFDelayTime);
                if (d) total += [d doubleValue];
            }
            CFRelease(props);
        }
    }
    CFRelease(src);
    if (total == 0) total = count * 0.1;
    return [UIImage animatedImageWithImages:imgs duration:total];
}

#pragma mark - 视频/GIF 叠加层

@interface PengMediaLayer : NSObject
+ (void)applyToView:(UIView *)view module:(NSString *)mod;
@end

@implementation PengMediaLayer

+ (void)applyToView:(UIView *)view module:(NSString *)mod {
    if (!view) return;
    // 防止重复添加
    static char kTag;
    if (objc_getAssociatedObject(view, &kTag)) return;
    objc_setAssociatedObject(view, &kTag, @(1), OBJC_ASSOCIATION_RETAIN);

    NSString *path = AssetPathForModule(mod);
    NSString *type = ModuleMediaType(mod);
    if (!path) return;

    if ([type isEqualToString:@"video"]) {
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:path]];
        AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
        layer.frame = view.bounds;
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        layer.masksToBounds = YES;
        [view.layer addSublayer:layer];
        [player play];
        player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        [[NSNotificationCenter defaultCenter]
            addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                        object:item
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n){
                        [player seekToTime:kCMTimeZero];
                    }];
    } else if ([type isEqualToString:@"gif"]) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:view.bounds];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.image = LoadGIF(path);
        iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [view addSubview:iv];
    }
}

@end

#pragma mark - Hook：替换静态图标

%hook CCUIButtonModule

- (UIImage *)glyphImage {
    NSString *mod = ModuleKeyForObject(self);
    if (mod && ModuleEnabled(mod)) {
        NSString *type = ModuleMediaType(mod);
        // 视频/GIF 走叠加层，这里只处理静态图
        if ([type isEqualToString:@"image"]) {
            UIImage *img = LoadImage(AssetPathForModule(mod));
            if (img) return img;
        }
    }
    return %orig;
}

%end

#pragma mark - Hook：在模块按钮上叠加视频/GIF

// 从 CCUIButton 取出其对应的模块实例（类名才在 ModuleMap 中）
static NSString *ModuleFromButton(id button) {
    id module = nil;
    // 1) 常见 ivar 名
    module = MSHookIvar<id>(button, "_module");
    if (!module) module = MSHookIvar<id>(button, "module");
    // 2) 属性 / KVC 兜底
    if (!module) {
        @try { module = [button valueForKey:@"module"]; } @catch (NSException *e) { module = nil; }
    }
    if (!module) return nil;
    return ModuleKeyForObject(module);
}

// CCUIButton 是控制中心模块的可见按钮控件
%hook CCUIButton

- (void)layoutSubviews {
    %orig;
    NSString *mod = ModuleFromButton(self);
    if (mod && ModuleEnabled(mod)) {
        NSString *type = ModuleMediaType(mod);
        if ([type isEqualToString:@"video"] || [type isEqualToString:@"gif"]) {
            [PengMediaLayer applyToView:self module:mod];
        }
    }
}

%end

#pragma mark - 构造函数

%ctor {
    // 确保素材目录存在（通常设置面板已创建）
    [[NSFileManager defaultManager] createDirectoryAtPath:kAssetsDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
}
