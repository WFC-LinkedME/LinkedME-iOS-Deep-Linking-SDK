//
//  LMSpotlightUrlRequest.m
//  iOS-Deep-Linking-SDK
//
//  Created on 7/23/15.
//  Copyright © 2015 Bindx. All rights reserved.
//

#import "LMSpotlightUrlRequest.h"

@interface LMSpotlightUrlRequest ()

@property (strong, nonatomic) callbackWithParams spotlightCallback;

@end

@implementation LMSpotlightUrlRequest

- (id)initWithParams:(NSDictionary *)params callback:(callbackWithParams)callback {
    LMLinkData *linkData = [[LMLinkData alloc] init];
    [linkData setupParams:params];
    [linkData setupChannel:@"spotlight"];
    
    if (self = [super initWithTags:nil alias:nil type:LinkedMELinkTypeUnlimitedUse matchDuration:0 channel:@"spotlight" feature:LINKEDME_FEATURE_TAG_SHARE stage:nil params:params linkData:linkData linkCache:nil callback:nil]) {
        _spotlightCallback = callback;
    }
    return self;
}

- (void)processResponse:(LMServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.spotlightCallback) {
            self.spotlightCallback(nil, error);
        }
    }
    else if (self.spotlightCallback) {
        self.spotlightCallback(response.data, nil);
    }
}

@end
