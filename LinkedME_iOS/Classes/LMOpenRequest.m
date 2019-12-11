//
//  LMOpenRequest.m
//  iOS-Deep-Linking-SDK
//
//  Created on 5/26/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//


#import "LMOpenRequest.h"
#import "LMPreferenceHelper.h"
#import "LMSystemObserver.h"
#import "LMConstants.h"
#import "LMEncodingUtils.h"
#import "LMDeviceInfo.h"
#import "LMSimulateIDFA.h"
#import "LKMEConfig.h"

#define IOS8 ([[[UIDevice currentDevice] systemVersion] doubleValue] >=8.0 ? YES : NO)

@interface LMOpenRequest ()

@property (assign, nonatomic) BOOL isInstall;
@property (strong, nonatomic) NSString * cookid;
@property (copy  , nonatomic) NSString * maping;

@end

@implementation LMOpenRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    return [self initWithCallback:callback isInstall:YES];
}

- (id)initWithCallback:(callbackWithStatus)callback isInstall:(BOOL)isInstall {
    
    if (self = [super init]) {
        _callback = callback;
        _isInstall = isInstall;
    }
    return self;
}

- (void)makeRequest:(LMServerInterface *)serverInterface key:(NSString *)key callback:(LMServerCallback)callback {
    
    self.maping = [[NSString alloc]init];
    
    @try {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        
        if ([pasteboard string].length>5) {
            _cookid = [pasteboard string];
        }
        
        if (_cookid.length >2) {
            NSString *checkString = _cookid;
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
        
    } @catch (NSException *exception) {
        
    } @finally {

    }
    
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    if (![preferenceHelper deviceFingerprintID]) {
        BOOL isRealHardwareId;
        LMDeviceInfo * deviceInfo=[LMSystemObserver getUniqueHardwareIdAndType:&isRealHardwareId andIsDebug:[preferenceHelper isDebug]];
        
        if (deviceInfo) {
            params[LINKEDME_REQUEST_KEY_DEVICE_ID] = [LMSystemObserver identifierByKeychain];//设备唯一标识
            params[LINKEDME_REQUEST_KEY_DEVICE_TYPE] = @(deviceInfo.deviceType);//设备类型
        }
    }else{
        params[LINKEDME_REQUEST_KEY_DEVICE_FINGERPRINT_ID]=preferenceHelper.deviceFingerprintID;//设备指纹ID
    }
//    BOOL isRealHardwareId;
    
    //browser_identity_id
    if (self.maping.length) {
        params[LINKEDME_BROWSER_IDENTITY_ID] = self.maping;
    }
    
    params[LINKEDME_REQUEST_KEY_LKME_IDENTITY]=preferenceHelper.identityID;//设备ID
    params[LINKEDME_REQUEST_KEY_AD_TRACKING_ENABLED] =@([LMSystemObserver adTrackingSafe]);
    params[LINKEDME_REQUEST_KEY_IS_REFERRABLE]=@(preferenceHelper.isReferrable);//当前请求是否为referrable
    //App版本
    [self safeSetValue:[LMSystemObserver getAppVersion] forKey:LINKEDME_REQUEST_KEY_APP_VERSION onDict:params];
    //模拟idfa
    [self safeSetValue:[LMSimulateIDFA createSimulateIDFA] forKey:@"SimlateIDFA" onDict:params];
    //唤起应用的来源链接 (iOS uri scheme)
    [self safeSetValue:preferenceHelper.externalIntentURI forKey:LKME_REQUEST_KEY_EXTERNAL_INTENT_URI onDict:params];
    //spotlight 标识符
    [self safeSetValue:preferenceHelper.spotlightIdentifier forKey:LINKEDME_REQUEST_KEY_SPOTLIGHT_IDENTIFIER onDict:params];
    //唤起应用的来源链接 (iOS https)
    [self safeSetValue:preferenceHelper.universalLinkUrl forKey:LINKEDME_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:params];
    //os 版本
    [self safeSetValue:[LMSystemObserver getOSVersion] forKey:LINKEDME_REQUEST_KEY_OS_VERSION onDict:params];
    //os 类型
    [self safeSetValue:[LMSystemObserver getOS] forKey:LINKEDME_REQUEST_KEY_OS onDict:params];
    //SDK更新状态标识
    [self safeSetValue:[LMSystemObserver getUpdateState] forKey:LINKEDME_REQUEST_KEY_UPDATE onDict:params];
    //idfa
    [self safeSetValue:[LMSystemObserver getIDFA] forKey:LINKEDME_REQUEST_KEY_OS_IDFA onDict:params];
    //idfv
    [self safeSetValue:[LMSystemObserver getIDFV] forKey:LINKEDME_REQUEST_KEY_OS_IDFV onDict:params];
    //sdk Version
    [self safeSetValue:SDK_VERSION forKey:LINKEDME_REQUEST_KEY_SDK_VERSION onDict:params];

    params[LINKEDME_REQUEST_KEY_IS_DEBUG]=@(preferenceHelper.isDebug);//是否Debug
    
    [serverInterface postRequest:params url:[preferenceHelper getSDKURL:LINKEDME_REQUEST_ENDPOINT_OPEN] key:key callback:callback];
    
}



- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

- (void)processResponse:(LMServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }
    
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    
    NSDictionary *data = response.data;
    
    if ([data[@"is_test_url"] boolValue]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"温馨提示" message:@"您的SDK已正确集成!\n(该提示只在扫描测试二维码时出现)" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    //callBackUrl
    preferenceHelper.linkClickIdentifier = nil;
    preferenceHelper.spotlightIdentifier = nil;
    preferenceHelper.universalLinkUrl = nil;
    preferenceHelper.externalIntentURI = nil;
    
    id userIdentity = data[LINKEDME_RESPONSE_KEY_DEVELOPER_IDENTITY];
    if ([userIdentity isKindOfClass:[NSNumber class]]) {
        userIdentity = [userIdentity stringValue];
    }
    
    preferenceHelper.deviceFingerprintID = data[LINKEDME_REQUEST_KEY_DEVICE_FINGERPRINT_ID];//
    preferenceHelper.userUrl = data[LINKEDME_RESPONSE_KEY_USER_URL];
    preferenceHelper.userIdentity = userIdentity;
    preferenceHelper.sessionID = [data[LINKEDME_RESPONSE_KEY_SESSION_ID] description];
    
    [LMSystemObserver setUpdateState];
    
    // Update session params
    BOOL isFirstSession=data[LINKEDME_RESPONSE_KEY_IS_FIRST_SESSION];
    BOOL dataIsFromALinkClick = data[LINKEDME_RESPONSE_KEY_CLICKED_LINKEDME_LINK];
    NSMutableDictionary *params ;
    
    if (data[LINKEDME_RESPONSE_KEY_SESSION_DATA]&&[data[LINKEDME_RESPONSE_KEY_SESSION_DATA] isKindOfClass:[NSDictionary class]]) {
        params = data[LINKEDME_RESPONSE_KEY_SESSION_DATA];
    }else{
        params= [NSMutableDictionary dictionary];
    }
    //    params [LKME_RESPONSE_KEY_SESSION_DATA] = data[LKME_RESPONSE_KEY_SESSION_DATA];
    params[LINKEDME_RESPONSE_KEY_IS_FIRST_SESSION]=@(isFirstSession);
    params[LINKEDME_RESPONSE_KEY_CLICKED_LINKEDME_LINK]=@(dataIsFromALinkClick);
    
    //获取页面地址
    preferenceHelper.callBackUrl = params[@"h5_url"];
    preferenceHelper.sessionParams = [[NSString alloc]initWithData: [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
    

    
    if (preferenceHelper.sessionParams && preferenceHelper.isReferrable) {
        if (dataIsFromALinkClick && (self.isInstall)) {
            preferenceHelper.installParams = [preferenceHelper.sessionParams copy];
            
        }
    }
    
    if (data[LINKEDME_REQUEST_KEY_LKME_IDENTITY]) {
        preferenceHelper.identityID = data[LINKEDME_RESPONSE_KEY_IDENTITY_ID];
    }
    
    if (self.callback) {
        self.callback(YES, nil);
    }
    
}

@end

