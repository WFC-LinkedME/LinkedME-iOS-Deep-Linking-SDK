//
//  LMSetIdentityRequest.m
//  iOS-Deep-Linking-SDK
//
//  Created on 5/22/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMSetIdentityRequest.h"
#import "LMPreferenceHelper.h"
#import "LMEncodingUtils.h"
#import "LMConstants.h"

@interface LMSetIdentityRequest ()

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) callbackWithParams callback;
@property (assign, nonatomic) BOOL shouldCallCallback;

@end

@implementation LMSetIdentityRequest

- (id)initWithUserId:(NSString *)userId callback:(callbackWithParams)callback {
    if (self = [super init]) {
        _userId = userId;
        _callback = callback;
        _shouldCallCallback = YES;
    }
    
    return self;
}

- (void)makeRequest:(LMServerInterface *)serverInterface key:(NSString *)key callback:(LMServerCallback)callback {
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    NSDictionary *params = @{
        LINKEDME_REQUEST_KEY_DEVELOPER_IDENTITY: self.userId,
        LINKEDME_REQUEST_KEY_DEVICE_FINGERPRINT_ID: preferenceHelper.deviceFingerprintID,
        LINKEDME_REQUEST_KEY_SESSION_ID: preferenceHelper.sessionID,
        LINKEDME_REQUEST_KEY_LKME_IDENTITY: preferenceHelper.identityID
    };

    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:LINKEDME_REQUEST_ENDPOINT_SET_IDENTITY] key:key callback:callback];
}

- (void)processResponse:(LMServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback && self.shouldCallCallback) {
            self.callback(nil, error);
        }
        
        self.shouldCallCallback = NO;
        return;
    }
    
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    preferenceHelper.identityID = response.data[LINKEDME_REQUEST_KEY_LKME_IDENTITY];
    preferenceHelper.userUrl = response.data[LINKEDME_RESPONSE_KEY_USER_URL];
    preferenceHelper.userIdentity = self.userId;
    if (response.data[LINKEDME_REQUEST_KEY_SESSION_ID]) {
        preferenceHelper.sessionID = response.data[LINKEDME_REQUEST_KEY_SESSION_ID];
    }
  
    if (response.data[LINKEDME_RESPONSE_KEY_INSTALL_PARAMS]) {
        preferenceHelper.installParams = response.data[LINKEDME_RESPONSE_KEY_INSTALL_PARAMS];
    }
    
    if (self.callback && self.shouldCallCallback) {
        NSString *storedParams = preferenceHelper.installParams;
        NSDictionary *installParams = [LMEncodingUtils decodeJsonStringToDictionary:storedParams];
        self.callback(installParams, nil);
    }
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _userId = [decoder decodeObjectForKey:@"userId"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.userId forKey:@"userId"];
}

@end
