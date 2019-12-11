//
//  LMLogoutRequest.m
//  iOS-Deep-Linking-SDK
//
//  Created on 5/22/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMLogoutRequest.h"
#import "LMPreferenceHelper.h"
#import "LMConstants.h"

@interface LMLogoutRequest ()

@property (strong, nonatomic) callbackWithStatus callback;

@end

@implementation LMLogoutRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    if (self = [super init]) {
        _callback = callback;
    }

    return self;
}

- (void)makeRequest:(LMServerInterface *)serverInterface key:(NSString *)key callback:(LMServerCallback)callback {
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];

     NSDictionary *params = @{
        LINKEDME_REQUEST_KEY_DEVICE_FINGERPRINT_ID: preferenceHelper.deviceFingerprintID,
        LINKEDME_REQUEST_KEY_SESSION_ID: preferenceHelper.sessionID,
        LINKEDME_REQUEST_KEY_LKME_IDENTITY: preferenceHelper.identityID
     };
    
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:LINKEDME_REQUEST_ENDPOINT_LOGOUT] key:key callback:callback];
}

- (void)processResponse:(LMServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }

    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    preferenceHelper.sessionID = response.data[LINKEDME_REQUEST_KEY_SESSION_ID];
    preferenceHelper.identityID = response.data[LINKEDME_RESPONSE_KEY_IDENTITY_ID];
    preferenceHelper.userUrl = response.data[LINKEDME_RESPONSE_KEY_USER_URL];
    preferenceHelper.userIdentity = nil;
    preferenceHelper.installParams = nil;
    preferenceHelper.sessionParams = nil;
    [preferenceHelper clearUserCreditsAndCounts];
    
    if (self.callback) {
        self.callback(YES, nil);
    }
}

@end
