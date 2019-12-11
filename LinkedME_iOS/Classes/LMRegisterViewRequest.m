//
//  LMRegisterViewRequest.m
//  iOS-Deep-Linking-SDK
//
//  Created on 10/16/15.
//  Copyright © 2015 Bindx. All rights reserved.
//

#import "LMRegisterViewRequest.h"
#import "LMPreferenceHelper.h"
#import "LMConstants.h"
#import "LMSystemObserver.h"

@interface LMRegisterViewRequest ()

@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) callbackWithParams callback;

@end

@implementation LMRegisterViewRequest

- (id)initWithParams:(NSDictionary *)params andCallback:(callbackWithParams)callback {
    if (self = [super init]) {
        _params = params;
        if (!_params) {
            _params = [[NSDictionary alloc] init];
        }
        _callback = callback;
    }
    
    return self;
}

- (void)makeRequest:(LMServerInterface *)serverInterface key:(NSString *)key callback:(LMServerCallback)callback {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    if (self.params) {
        data[LINKEDME_REQUEST_KEY_URL_DATA] = [self.params copy];
    }
    
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    [self safeSetValue:preferenceHelper.deviceFingerprintID forKey:LINKEDME_REQUEST_KEY_DEVICE_FINGERPRINT_ID onDict:data];
    [self safeSetValue:preferenceHelper.identityID forKey:LINKEDME_REQUEST_KEY_LKME_IDENTITY onDict:data];
    [self safeSetValue:preferenceHelper.sessionID forKey:LINKEDME_REQUEST_KEY_SESSION_ID onDict:data];
    [self safeSetValue:@([LMSystemObserver adTrackingSafe]) forKey:LINKEDME_REQUEST_KEY_AD_TRACKING_ENABLED onDict:data];
    [self safeSetValue:@(preferenceHelper.isDebug) forKey:LINKEDME_REQUEST_KEY_DEBUG onDict:data];
    [self safeSetValue:[LMSystemObserver getOS] forKey:LINKEDME_REQUEST_KEY_OS onDict:data];
    [self safeSetValue:[LMSystemObserver getOSVersion] forKey:LINKEDME_REQUEST_KEY_OS_VERSION onDict:data];
    [self safeSetValue:[LMSystemObserver getModel] forKey:LINKEDME_REQUEST_KEY_MODEL onDict:data];
    [self safeSetValue:@([LMSystemObserver isSimulator]) forKey:LINKEDME_REQUEST_KEY_IS_SIMULATOR onDict:data];

    [self safeSetValue:[LMSystemObserver getAppVersion] forKey:LINKEDME_REQUEST_KEY_APP_VERSION onDict:data];
    [self safeSetValue:[LMSystemObserver getDeviceName] forKey:LINKEDME_REQUEST_KEY_DEVICE_NAME onDict:data];

    BOOL isRealHardwareId;
    NSString *hardwareId = [LMSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:preferenceHelper.isDebug];
    if (hardwareId && isRealHardwareId) {
        data[LINKEDME_REQUEST_KEY_HARDWARE_ID] = hardwareId;
    }
    
    [serverInterface postRequest:data url:[preferenceHelper getAPIURL:LINKEDME_REQUEST_ENDPOINT_REGISTER_VIEW] key:key callback:callback];
}

- (void)processResponse:(LMServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(nil, error);
        }
        return;
    }
    
    if (self.callback) {
        self.callback(response.data, error);
    }
}

- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _params = [decoder decodeObjectForKey:@"params"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.params forKey:@"params"];
}

@end
