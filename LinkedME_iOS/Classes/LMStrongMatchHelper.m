//
//  LMStrongMatchHelper.m
//  iOS-Deep-Linking-SDK
//
//  Created on 8/26/15.
//  Copyright © 2015 Bindx. All rights reserved.
//

#import "LMStrongMatchHelper.h"
#import "LKMEConfig.h"
#import "LMPreferenceHelper.h"
#import "LMSystemObserver.h"
#import "LMConstants.h"

// Stub the class for older Xcode versions, methods don't actually do anything.
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000

@implementation LKMEStrongMatchHelper

+ (LKMEStrongMatchHelper *)strongMatchHelper { return nil; }
- (void)createStrongMatchWithLinkedMEKey:(NSString *)linkedMEKey { }
- (BOOL)shouldDelayInstallRequest { return NO; }

@end

#else

NSInteger const ABOUT_30_DAYS_TIME_IN_SECONDS = 60 * 60 * 24 * 30;

@interface LMStrongMatchHelper ()

@property (strong, nonatomic) UIWindow *secondWindow;
@property (assign, nonatomic) BOOL requestInProgress;
@property (assign, nonatomic) BOOL shouldDelayInstallRequest;

@end

@implementation LMStrongMatchHelper

+ (LMStrongMatchHelper *)strongMatchHelper {
    static LMStrongMatchHelper *strongMatchHelper;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        strongMatchHelper = [[LMStrongMatchHelper alloc] init];
    });
    
    return strongMatchHelper;
}

- (void)createStrongMatchWithLinkedMEKey:(NSString *)linkedMEKey {
    if (self.requestInProgress) {
        return;
    }

    self.requestInProgress = YES;
    
    NSDate *thirtyDaysAgo = [NSDate dateWithTimeIntervalSinceNow:-ABOUT_30_DAYS_TIME_IN_SECONDS];
    NSDate *lastCheck = [LMPreferenceHelper preferenceHelper].lastStrongMatchDate;
    
//    当实例保存的日期值与anotherDate相同时返回NSOrderedSame
//    当实例保存的日期值晚于anotherDate时返回NSOrderedDescending
//    当实例保存的日期值早于anotherDate时返回NSOrderedAscending
    if ([lastCheck compare:thirtyDaysAgo] == NSOrderedDescending){
        self.requestInProgress = NO;
        return;
    }
    
    self.shouldDelayInstallRequest = YES;
    [self presentSafariVCWithLinkedMEKey:linkedMEKey];
}

- (void)presentSafariVCWithLinkedMEKey:(NSString *)linkedMEKey {
    
    NSMutableString *urlString = [[NSMutableString alloc] initWithFormat:@"%@/_strong_match?os=%@", LKME_LINK_URL, [LMSystemObserver getOS]];
    
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    BOOL isRealHardwareId;
    NSString *hardwareId = [LMSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:preferenceHelper.isDebug];
    if (!hardwareId || !isRealHardwareId) {
        NSLog(@"[Linkedme Warning] Cannot use cookie-based matching while setDebug is enabled");
        self.shouldDelayInstallRequest = NO;
        self.requestInProgress = NO;
        return;
    }
    
    [urlString appendFormat:@"&%@=%@", LINKEDME_REQUEST_KEY_HARDWARE_ID, hardwareId];

    if (preferenceHelper.deviceFingerprintID) {
        [urlString appendFormat:@"&%@=%@", LINKEDME_REQUEST_KEY_DEVICE_FINGERPRINT_ID, preferenceHelper.deviceFingerprintID];
    }

    if ([LMSystemObserver getAppVersion]) {
        [urlString appendFormat:@"&%@=%@", LINKEDME_REQUEST_KEY_APP_VERSION, [LMSystemObserver getAppVersion]];
    }

    if (linkedMEKey) {
        if ([linkedMEKey hasPrefix:@"key_"]) {
            [urlString appendFormat:@"&linkedME_key=%@", linkedMEKey];
        }
        else {
            [urlString appendFormat:@"&app_id=%@", linkedMEKey];
        }
    }

    [urlString appendFormat:@"&sdk=ios%@", SDK_VERSION];
    
    Class SFSafariViewControllerClass = NSClassFromString(@"SFSafariViewController");
    if (SFSafariViewControllerClass && preferenceHelper.getSafariCookice) {
        UIViewController * safController = [[SFSafariViewControllerClass alloc] initWithURL:[NSURL URLWithString:urlString]];
        
        self.secondWindow = [[UIWindow alloc] initWithFrame:[[[[UIApplication sharedApplication] delegate] window] bounds]];
        UIViewController *windowRootController = [[UIViewController alloc] init];
        self.secondWindow.rootViewController = windowRootController;
        self.secondWindow.windowLevel = UIWindowLevelNormal - 1;
        [self.secondWindow setHidden:NO];
        [self.secondWindow setAlpha:0];
        
        // Must be on next run loop to avoid a warning
        dispatch_async(dispatch_get_main_queue(), ^{
            // Add the safari view controller using view controller containment
            [windowRootController addChildViewController:safController];
            [windowRootController.view addSubview:safController.view];
            [safController didMoveToParentViewController:windowRootController];
            
            // Give a little bit of time for safari to load the request.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // Remove the safari view controller from view controller containment
                [safController willMoveToParentViewController:nil];
                [safController.view removeFromSuperview];
                [safController removeFromParentViewController];
                
                // Remove the window and release it's strong reference. This is important to ensure that
                // applications using view controller based status bar appearance are restored.
                [self.secondWindow removeFromSuperview];
                self.secondWindow = nil;
                
                [LMPreferenceHelper preferenceHelper].lastStrongMatchDate = [NSDate date];
                self.requestInProgress = NO;
            });
        });
    }
    else {
        self.requestInProgress = NO;
    }
}

- (BOOL)shouldDelayInstallRequest {
    return _shouldDelayInstallRequest;
}


@end

#endif
