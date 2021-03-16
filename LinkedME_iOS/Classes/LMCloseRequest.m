//
//  LMCloseRequest.m
//  iOS-Deep-Linking-SDK
//
//  Created on 5/26/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMPreferenceHelper.h"
#import "LMCloseRequest.h"
#import "LMConstants.h"
#import "LMDeviceInfo.h"
#import "LMSystemObserver.h"
#import "LMEncodingUtils.h"

@implementation LMCloseRequest

- (void)makeRequest:(LMServerInterface*)serverInterface key:(NSString*)key callback:(LMServerCallback)callback{
    LMPreferenceHelper* preferenceHelper = [LMPreferenceHelper preferenceHelper];

    BOOL isRealHardwareId;
    LMDeviceInfo * deviceInfo=[LMSystemObserver getUniqueHardwareIdAndType:&isRealHardwareId andIsDebug:[preferenceHelper isDebug]];
   
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    //device_type
    params[LINKEDME_REQUEST_KEY_DEVICE_TYPE] = @(deviceInfo.deviceType);
    //device_id
    params[LINKEDME_REQUEST_KEY_DEVICE_ID] = [LMSystemObserver identifierByKeychain];
    //device_type
    params[LINKEDME_REQUEST_KEY_DEVICE_MODEL] = [LMDeviceInfo getModel];
    //device_name
    params[LINKEDME_REQUEST_KEY_DEVICE_NAME] = [UIDevice currentDevice].name;
    //identityID
    [self safeSetValue:preferenceHelper.identityID forKey:LINKEDME_RESPONSE_KEY_IDENTITY_ID onDict:params];
    //sessionID
    [self safeSetValue:preferenceHelper.sessionID forKey:LINKEDME_REQUEST_KEY_SESSION_ID onDict:params];
    //deviceFingerPrintID
    [self safeSetValue:preferenceHelper.deviceFingerprintID forKey:LINKEDME_REQUEST_KEY_DEVICE_FINGERPRINT_ID onDict:params];
    //DeviceID
//  [self safeSetValue:[LMSystemObserver identifierByKeychain] forKey:LINKEDME_REQUEST_KEY_DEVICE_ID onDict:params];
    //device_id
    params[LINKEDME_REQUEST_KEY_DEVICE_ID] = [LMSystemObserver identifierByKeychain];
        //device_name
    params[LINKEDME_REQUEST_KEY_DEVICE_NAME] = [UIDevice currentDevice].name;
    //idfa
    [self safeSetValue:[LMSystemObserver getIDFA] forKey:LINKEDME_REQUEST_KEY_OS_IDFA onDict:params];
    //idfv
    [self safeSetValue:[LMSystemObserver getIDFV] forKey:LINKEDME_REQUEST_KEY_OS_IDFV onDict:params];
#if !TARGET_IPHONE_SIMULATOR//真机
    if (preferenceHelper.closeSession) {
        [self safeSetValue:preferenceHelper.closeSession forKey:@"close_session" onDict:params];
    }
#endif
    NSLog(@"close:%@",params);
//    [serverInterface postRequest:params url:[preferenceHelper getSDKURL:LINKEDME_REQUEST_ENDPOINT_CLOSE] key:key callback:callback];
    [serverInterface postRequest:params url:[preferenceHelper getSDKURL:LINKEDME_REQUEST_ENDPOINT_CLOSE] key:key callback:^(LMServerResponse *response, NSError *error) {
        NSLog(@"***********closeSuccess*************");
    }];
}

- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

- (void)processResponse:(LMServerResponse*)response error:(NSError*)error{
    // Nothing to see here
    NSLog(@"***********closeSuccess*************");
}

@end
 

