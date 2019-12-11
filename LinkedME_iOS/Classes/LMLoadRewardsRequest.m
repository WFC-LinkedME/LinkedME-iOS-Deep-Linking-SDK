//
//  LMLoadRewardsRequest.m
//  iOS-Deep-Linking-SDK
//
//  Created on 5/22/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMLoadRewardsRequest.h"
#import "LMPreferenceHelper.h"
#import "LMConstants.h"

@interface LMLoadRewardsRequest ()

@property (strong, nonatomic) callbackWithStatus callback;

@end

@implementation LMLoadRewardsRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    if (self = [super init]) {
        _callback = callback;
    }
    return self;
}

- (void)makeRequest:(LMServerInterface *)serverInterface key:(NSString *)key callback:(LMServerCallback)callback {
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    NSString *endpoint = [LINKEDME_REQUEST_ENDPOINT_LOAD_REWARDS stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",preferenceHelper.identityID]];
    [serverInterface getRequest:nil url:[preferenceHelper getAPIURL:endpoint] key:key callback:callback];
}

- (void)processResponse:(LMServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }

    BOOL hasUpdated = NO;
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    NSDictionary *currentCreditDictionary = [preferenceHelper getCreditDictionary];
    NSArray *responseKeys = [response.data allKeys];
    NSArray *storedKeys = [currentCreditDictionary allKeys];

    if ([responseKeys count]) {
        for (NSString *key in response.data) {
             NSInteger credits = [response.data[key] integerValue];

             LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
             if (credits != [preferenceHelper getCreditCountForBucket:key]) {
                 hasUpdated = YES;
             }

             [preferenceHelper setCreditCount:credits forBucket:key];
        }
        for(NSString *key in storedKeys) {
            if(![response.data objectForKey:key]) {
                [preferenceHelper removeCreditCountForBucket:key];
                hasUpdated = YES;
            }
        }
    } else {
        if ([storedKeys count]) {
            [preferenceHelper clearUserCredits];
            hasUpdated = YES;
        }
    }

    if (self.callback) {
        self.callback(hasUpdated, nil);
    }
}

@end
