//
//  LMInstallRequest.m
//  iOS-Deep-Linking-SDK
//
//  Created on 5/26/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMInstallRequest.h"
#import "LMPreferenceHelper.h"
#import "LMSystemObserver.h"
#import "LMConstants.h"
#import "LMStrongMatchHelper.h"
#import "LMDeviceInfo.h"
#import "LMApplication.h"
#import "LMEncodingUtils.h"
#import "LKMEConfig.h"

#define IOS8 ([[[UIDevice currentDevice] systemVersion] doubleValue] >=8.0 ? YES : NO)
@interface LMInstallRequest ()

@property (strong, nonatomic) NSString * cookid;
@property (copy,   nonatomic) NSString * maping;

@end

@implementation LMInstallRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    return [super initWithCallback:callback isInstall:YES];
}

- (void)makeRequest:(LMServerInterface *)serverInterface key:(NSString *)key callback:(LMServerCallback)callback {        LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];

    self.maping = [[NSString alloc]init];
    
    @try {
        
        dispatch_queue_t queue = dispatch_queue_create("com.LinkPage.installQueue", DISPATCH_QUEUE_CONCURRENT);
        
        if (preferenceHelper.disableClipboardMatch == NO) {
        dispatch_async(queue, ^{
            
           UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
           
            __weak typeof(self) weakSelf = self;

           if ([pasteboard string].length>5) {
               weakSelf.cookid = [pasteboard string];
           }
           
             if (weakSelf.cookid.length >2) {
                   NSString *checkString = weakSelf.cookid;
                   NSString *pattern = @"`\\+(.+)`\\+";
                   if (pattern) {
                       NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
                       if (regular) {
                           NSTextCheckingResult *result = [regular firstMatchInString:checkString options:0 range:NSMakeRange(0, [checkString length])];
                           if (result) {
                               if ([result rangeAtIndex:1].length) {
                                   self.maping = [checkString substringWithRange:[result rangeAtIndex:1]];
                                   pasteboard.string = @"";
                               }
                           }
                       }
                   }
               }
            });
        }
        
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    BOOL isRealHardwareId;
    
    LMDeviceInfo * deviceInfo= [LMSystemObserver getUniqueHardwareIdAndType:&isRealHardwareId andIsDebug:preferenceHelper.isDebug];
    
    if (deviceInfo) {
        params[LINKEDME_REQUEST_KEY_DEVICE_ID] = [LMSystemObserver identifierByKeychain];
        params[LINKEDME_REQUEST_KEY_DEVICE_TYPE] = @(deviceInfo.deviceType);
    }
    
    [self safeSetValue:[LMSystemObserver getLinkedME] forKey:LINKEDME_REQUEST_KEY_DEVICE_BRAND onDict:params];
    
//    [self safeSetValue:[LMSimulateIDFA createSimulateIDFA] forKey:@"SimlateIDFA" onDict:params];
    
    [self safeSetValue:[LMSystemObserver getModel] forKey:LINKEDME_REQUEST_KEY_DEVICE_MODEL onDict:params];
    [self safeSetValue:[LMSystemObserver getOS] forKey:LINKEDME_REQUEST_KEY_OS onDict:params];
    [self safeSetValue:[LMSystemObserver getOSVersion] forKey:LINKEDME_REQUEST_KEY_OS_VERSION onDict:params];
    params[LINKEDME_REQUEST_KEY_IS_REFERRABLE]=@(preferenceHelper.isReferrable);
    params[LINKEDME_REQUEST_KEY_IS_DEBUG]=@(preferenceHelper.isDebug);
    [self safeSetValue:[LMSystemObserver getCarrier] forKey:LINKEDME_REQUEST_KEY_CARRIER onDict:params];
    [self safeSetValue:[LMSystemObserver getAppVersion] forKey:LINKEDME_REQUEST_KEY_APP_VERSION onDict:params];
    [self safeSetValue:preferenceHelper.spotlightIdentifier forKey:LINKEDME_REQUEST_KEY_SPOTLIGHT_IDENTIFIER onDict:params];
    [self safeSetValue:preferenceHelper.universalLinkUrl forKey:LINKEDME_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:params];
    [self safeSetValue:[LMSystemObserver getUpdateState] forKey:LINKEDME_REQUEST_KEY_UPDATE onDict:params];
    [self safeSetValue:SDK_VERSION forKey:LINKEDME_REQUEST_KEY_SDK_VERSION onDict:params];
    
    params[LINKEDME_REQUEST_KEY_AD_TRACKING_ENABLED]=@([LMSystemObserver adTrackingSafe]);
    
    //browser_identity_id
    if (self.maping.length) {
        params[LINKEDME_BROWSER_IDENTITY_ID] = self.maping;
    }
    
    [self safeSetValue:[LMSystemObserver getBundleID] forKey:LINKEDME_REQUEST_KEY_BUNDLE_ID onDict:params];
    [self safeSetValue:[LMSystemObserver getTeamIdentifier] forKey:LINKEDME_REQUEST_KEY_TEAM_ID onDict:params];
    [self safeSetValue:[LMSystemObserver getScreenWidth] forKey:LINKEDME_REQUEST_KEY_SCREEN_WIDTH onDict:params];
    [self safeSetValue:[LMSystemObserver getScreenHeight] forKey:LINKEDME_REQUEST_KEY_SCREEN_HEIGHT onDict:params];
    [self safeSetValue:preferenceHelper.externalIntentURI forKey:LKME_REQUEST_KEY_EXTERNAL_INTENT_URI onDict:params];
    //idfa
    [self safeSetValue:[LMSystemObserver getIDFA] forKey:LINKEDME_REQUEST_KEY_OS_IDFA onDict:params];
    //idfv
    [self safeSetValue:[LMSystemObserver getIDFV] forKey:LINKEDME_REQUEST_KEY_OS_IDFV onDict:params];
    
    LMApplication *application = [LMApplication currentApplication];
    params[@"lastest_update_time"] = LMWireFormatFromDate(application.currentBuildDate);
    params[@"previous_update_time"] = LMWireFormatFromDate(preferenceHelper.previousAppBuildDate);
    params[@"latest_install_time"] = LMWireFormatFromDate(application.currentInstallDate);
    params[@"first_install_time"] = LMWireFormatFromDate(application.firstInstallDate);
    
    NSInteger delay = 750;
//    NSEC_PER_SEC表示的是秒数，它还提供了NSEC_PER_MSEC表示毫秒。
    if ([[LMStrongMatchHelper strongMatchHelper] shouldDelayInstallRequest]){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [serverInterface postRequest:params url:[preferenceHelper getSDKURL:LINKEDME_REQUEST_ENDPOINT_INSTALL] key:key callback:callback];
        });
    }else {
        [serverInterface postRequest:params url:[preferenceHelper getSDKURL:LINKEDME_REQUEST_ENDPOINT_INSTALL] key:key callback:callback];
    }
}

- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

@end
