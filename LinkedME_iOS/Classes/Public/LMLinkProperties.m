//
//  LMLinkProperties.m
//  iOS-Deep-Linking-SDK
//
//  Created on 10/16/15.
//  Copyright © 2015 Bindx. All rights reserved.
//

#import "LMLinkProperties.h"
#import "LMConstants.h"
#import "LMEncodingUtils.h"


@implementation LMLinkProperties

- (NSDictionary *)controlParams {
    if (!_controlParams) {
        _controlParams = [[NSDictionary alloc] init];
    }
    return _controlParams;
}

- (void)addControlParam:(NSString *)controlParam withValue:(NSString *)value {
    if (!controlParam || !value) {
        return;
    }
    NSMutableDictionary *temp = [self.controlParams mutableCopy];
    temp[controlParam] = [LMEncodingUtils urlEncodedString: value];
    _controlParams = [temp copy];
}

+ (LMLinkProperties *)getLinkedMELinkPropertiesFromDictionary:(NSDictionary *)dictionary {
    LMLinkProperties *linkProperties = [[LMLinkProperties alloc] init];
    
    if (dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_TAGS]]) {
        linkProperties.tags = [LMEncodingUtils urlEncodedString:dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_TAGS]]];
    }
    if (dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_STAGE]]) {
           linkProperties.state = [LMEncodingUtils urlEncodedString:dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_STAGE]]];
       }
    if (dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_FEATURE]]) {
        linkProperties.feature = [LMEncodingUtils urlEncodedString: dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_FEATURE]]];
    }
    if (dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_ALIAS]]) {
        linkProperties.alias = [LMEncodingUtils urlEncodedString: dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_ALIAS]]];
    }
    if (dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_CHANNEL]]) {
        linkProperties.channel = [LMEncodingUtils urlEncodedString: dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_CHANNEL]]];
    }
    if (dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_STAGE]]) {
        linkProperties.stage = [LMEncodingUtils urlEncodedString: dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_STAGE]]];
    }
    if (dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_DURATION]]) {
        linkProperties.matchDuration = [dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_DURATION]] intValue];
    }
    if (dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_STAGE]]) {
        linkProperties.stage = [LMEncodingUtils urlEncodedString: dictionary[[NSString stringWithFormat:@"~%@", LINKEDME_REQUEST_KEY_URL_STAGE]]];
    }
    linkProperties.source = @"~iOS";
    
    NSMutableDictionary *controlParams = [[NSMutableDictionary alloc] init];
    for (NSString *oneKey in dictionary.allKeys) {
        if ([oneKey hasPrefix:@"$"]) {
            controlParams[oneKey] = dictionary[oneKey];
        }
    }
    
    linkProperties.controlParams = controlParams;
    
    return linkProperties;
}


- (void)setAndroidPathControlParam:(NSString *) value{
    _androidPathControlParam = value;
    [self addControlParam:PARAMS_ANDROID_LINK withValue:_androidPathControlParam];
}

-(void)setIOSKeyControlParam:(NSString *)iOSKeyControlParam{
    _iOSKeyControlParam = iOSKeyControlParam;
    [self addControlParam:PARAMS_IOS_LINK withValue:_iOSKeyControlParam];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"LinkedMELinkProperties | tags: %@ \n feature: %@ \n alias: %@ \n channel: %@ \n stage: %@ \n matchDuration: %lu \n controlParams: %@", self.tags, self.feature, self.alias, self.channel, self.stage, (long)self.matchDuration, self.controlParams];
}

@end
