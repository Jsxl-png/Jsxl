#import "PengCCIconsPrefs.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

static NSString *const kPrefsID   = @"com.peng.ccicons";
static NSString *const kAssetsDir = @"/var/mobile/Library/Preferences/com.peng.ccicons/Assets";

@implementation PengCCIconsPrefs

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

#pragma mark - 打开相册选择素材

- (void)pickAsset:(PSSpecifier *)specifier {
    NSString *module = [specifier propertyForKey:@"moduleKey"];
    if (!module) return;

    // 记录当前模块，供回调使用
    objc_setAssociatedObject(self, "currentModule", module, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // 申请相册权限
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status != PHAuthorizationStatusAuthorized) {
                UIAlertController *a = [UIAlertController
                    alertControllerWithTitle:@"需要相册权限"
                                     message:@"请在系统设置中允许本插件访问照片。"
                              preferredStyle:UIAlertControllerStyleAlert];
                [a addAction:[UIAlertAction actionWithTitle:@"好"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
                [self presentViewController:a animated:YES completion:nil];
                return;
            }
            [self presentImagePicker];
        });
    }];
}

- (void)presentImagePicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - 相册回调：导出素材到本地

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {

    [picker dismissViewControllerAnimated:YES completion:nil];

    NSString *module = objc_getAssociatedObject(self, "currentModule");
    if (!module) return;

    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
    NSURL *refURL   = info[UIImagePickerControllerReferenceURL];
    NSString *type  = @"image";

    [[NSFileManager defaultManager] createDirectoryAtPath:kAssetsDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    NSString *savedName = nil;

    if (videoURL) {
        // 视频 / GIF（系统常以视频形式导出）
        type = @"video";
        savedName = [NSString stringWithFormat:@"%@.mov", module];
        NSString *dest = [kAssetsDir stringByAppendingPathComponent:savedName];
        [[NSFileManager defaultManager] removeItemAtPath:dest error:nil];
        [[NSFileManager defaultManager] copyItemAtPath:videoURL.path toPath:dest error:nil];
    } else if (refURL) {
        // 从相册资源导出原件（保留 GIF 动画）
        PHAsset *asset = [PHAsset fetchAssetsWithALAssetURLs:@[refURL] options:nil].firstObject;
        if (asset) {
            PHImageRequestOptions *opt = [[PHImageRequestOptions alloc] init];
            opt.version = PHImageRequestOptionsVersionOriginal;
            opt.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            [[PHImageManager defaultManager]
                requestImageDataForAsset:asset
                                 options:opt
                           resultHandler:^(NSData *data, NSString *uti, UIImageOrientation o, NSDictionary *info2) {
                NSString *ext = @"png";
                if ([uti isEqualToString:(NSString *)kUTTypeGIF]) { ext = @"gif"; type = @"gif"; }
                if ([uti isEqualToString:(NSString *)kUTTypeMovie] ||
                    [uti isEqualToString:(NSString *)kUTTypeVideo]) { ext = @"mov"; type = @"video"; }
                NSString *dest = [kAssetsDir stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"%@.%@", module, ext]];
                [data writeToFile:dest atomically:YES];
                [self commitModule:module asset:savedName ?: [NSString stringWithFormat:@"%@.%@", module, ext] type:type];
            }];
            return; // 异步，稍后提交
        }
    } else {
        // 直接拿到 UIImage（非 GIF）
        UIImage *img = info[UIImagePickerControllerOriginalImage];
        if (img) {
            savedName = [NSString stringWithFormat:@"%@.png", module];
            NSString *dest = [kAssetsDir stringByAppendingPathComponent:savedName];
            [UIImagePNGRepresentation(img) writeToFile:dest atomically:YES];
        }
    }

    if (savedName) {
        [self commitModule:module asset:savedName type:type];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 写入设置项

- (void)commitModule:(NSString *)module asset:(NSString *)asset type:(NSString *)type {
    CFStringRef app = (__bridge CFStringRef)kPrefsID;
    CFPreferencesSetAppValue((__bridge CFStringRef)
        [NSString stringWithFormat:@"Module_%@_Asset", module], (__bridge CFStringRef)asset, app);
    CFPreferencesSetAppValue((__bridge CFStringRef)
        [NSString stringWithFormat:@"Module_%@_Type", module], (__bridge CFStringRef)type, app);
    CFPreferencesSetAppValue((__bridge CFStringRef)
        [NSString stringWithFormat:@"Module_%@_Enabled", module], kCFBooleanTrue, app);
    CFPreferencesAppSynchronize(app);

    // 通知 SpringBoard 刷新控制中心
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.peng.ccicons/settingsChanged"), NULL, NULL, TRUE);

    [self reloadSpecifiers];
}

@end
