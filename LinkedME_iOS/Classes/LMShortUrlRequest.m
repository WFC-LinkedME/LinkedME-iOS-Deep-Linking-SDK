//
//  LMShortUrlRequest.m
//  iOS-Deep-Linking-SDK
//
//  Created on 5/26/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMShortUrlRequest.h"
#import "LMPreferenceHelper.h"
#import "LMEncodingUtils.h"
#import "LMConstants.h"
#import "LMDeviceInfo.h"
#import "LMSystemObserver.h"

@interface LMShortUrlRequest ()

@property (strong, nonatomic) NSArray *tags;
@property (strong, nonatomic) NSString *alias;
@property (assign, nonatomic) LMLinkType type;
@property (assign, nonatomic) NSInteger matchDuration;
@property (strong, nonatomic) NSString *channel;
@property (strong, nonatomic) NSString *feature;
@property (strong, nonatomic) NSString *stage;
@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) LMLinkCache *linkCache;
@property (strong, nonatomic) LMLinkData *linkData;
@property (strong, nonatomic) callbackWithUrl callback;

@end

@implementation LMShortUrlRequest

- (id)initWithTags:(NSArray *)tags alias:(NSString *)alias type:(LMLinkType)type matchDuration:(NSInteger)duration channel:(NSString *)channel feature:(NSString *)feature stage:(NSString *)stage params:(NSDictionary *)params linkData:(LMLinkData *)linkData linkCache:(LMLinkCache *)linkCache callback:(callbackWithUrl)callback {
    if (self = [super init]) {
        _tags = tags;
        _alias = alias;
        _type = type;
        _matchDuration = duration;
        _channel = channel;
        _feature = feature;
        _stage = stage;
        _params = params;
        _callback = callback;
        _linkCache = linkCache;
        _linkData = linkData;
    }
    return self;
}

- (void)makeRequest:(LMServerInterface *)serverInterface key:(NSString *)key callback:(LMServerCallback)callback {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:self.linkData.data];
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    
    BOOL isRealHardwareId;
    LMDeviceInfo * deviceInfo=[LMSystemObserver getUniqueHardwareIdAndType:&isRealHardwareId andIsDebug:[preferenceHelper isDebug]];
    
    if (deviceInfo) {
        params[LINKEDME_REQUEST_KEY_DEVICE_ID] = [LMSystemObserver identifierByKeychain];//设备唯一标识
        params[LINKEDME_REQUEST_KEY_DEVICE_TYPE] = @(deviceInfo.deviceType);//设备类型
    }
    
    params[LINKEDME_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    params[LINKEDME_RESPONSE_KEY_IDENTITY_ID] = [NSString stringWithFormat:@"%@",preferenceHelper.identityID];
    params[LINKEDME_RESPONSE_KEY_SESSION_ID] =[NSString stringWithFormat:@"%@",preferenceHelper.sessionID];
    
    //为了和js sdk统一，生成MD5时如果有“linkedme_live_”就去除。
    NSMutableString *lkme_key = [[NSMutableString alloc]initWithString:key];
    NSRange range = [lkme_key rangeOfString:@"linkedme_live_"];
    if (range.length) {
        [lkme_key deleteCharactersInRange:range];
    }
    
    //生成深度链接MD5
    params[@"deeplink_md5_new"] =[LMEncodingUtils md5Encode:[NSString stringWithFormat:@"%@&%@&%@&%@&%@&%@",
                                                         lkme_key,//LinkedME_key
                                                         self.tags?[self.tags componentsJoinedByString:@","]:@"",//标签
                                                         self.channel?self.channel:@"",//渠道
                                                         self.feature?self.feature:@"",//功能
                                                         self.stage?self.stage:@"",//阶段
                                                         params[@"params"]]];

    [serverInterface postRequest:params url:[preferenceHelper getSDKURL:LINKEDME_REQUEST_ENDPOINT_GET_SHORT_URL] key:key callback:callback];
}

- (NSString*)dictionaryToJson:(NSDictionary *)dic{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)processResponse:(LMServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            NSString *failedUrl = nil;
            NSString *userUrl = [LMPreferenceHelper preferenceHelper].userUrl;
            if (userUrl) {
                failedUrl = [self createLongUrlForUserUrl:userUrl];
            }
            
            self.callback(failedUrl, error);
        }
        
        return;
    }
    
    NSString *url = response.data[LKME_RESPONSE_KEY_URL];
    
    if (url) {
        [self.linkCache setObject:url forKey:self.linkData];
    }
    
    if (self.callback) {
        self.callback(url, nil);
    }
}

- (NSString *)createLongUrlForUserUrl:(NSString *)userUrl {
    NSMutableString *longUrl = [[NSMutableString alloc] initWithFormat:@"%@?", userUrl];
    
    for (NSString *tag in self.tags) {
        [longUrl appendFormat:@"tags=%@&", tag];
    }
    
    if ([self.alias length]) {
        [longUrl appendFormat:@"alias=%@&", self.alias];
    }
    
    if ([self.channel length]) {
        [longUrl appendFormat:@"channel=%@&", self.channel];
    }
    
    if ([self.feature length]) {
        [longUrl appendFormat:@"feature=%@&", self.feature];
    }
    
    if ([self.stage length]) {
        [longUrl appendFormat:@"stage=%@&", self.stage];
    }
    
    [longUrl appendFormat:@"type=%ld&", (long)self.type];
    [longUrl appendFormat:@"duration=%ld&", (long)self.matchDuration];
    
    NSData *jsonData = [LMEncodingUtils encodeDictionaryToJsonData:self.params];
    NSString *base64EncodedParams = [LMEncodingUtils base64EncodeData:jsonData];
    [longUrl appendFormat:@"source=ios&data=%@", base64EncodedParams];
    
    return longUrl;
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _tags = [decoder decodeObjectForKey:@"tags"];
        _alias = [decoder decodeObjectForKey:@"alias"];
        _type = [decoder decodeIntegerForKey:@"type"];
        _matchDuration = [decoder decodeIntegerForKey:@"duration"];
        _channel = [decoder decodeObjectForKey:@"channel"];
        _feature = [decoder decodeObjectForKey:@"feature"];
        _stage = [decoder decodeObjectForKey:@"stage"];
        _params = [LMEncodingUtils decodeJsonStringToDictionary:[decoder decodeObjectForKey:@"params"]];
        
        // Set up link data
        self.linkData = [[LMLinkData alloc] init];
        [self.linkData setupType:_type];
        [self.linkData setupTags:_tags];
        [self.linkData setupChannel:_channel];
        [self.linkData setupFeature:_feature];
        [self.linkData setupStage:_stage];
        [self.linkData setupAlias:_alias];
        [self.linkData setupMatchDuration:_matchDuration];
        [self.linkData setupParams:_params];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.tags forKey:@"tags"];
    [coder encodeObject:self.alias forKey:@"alias"];
    [coder encodeInteger:self.type forKey:@"type"];
    [coder encodeInteger:self.matchDuration forKey:@"duration"];
    [coder encodeObject:self.channel forKey:@"channel"];
    [coder encodeObject:self.feature forKey:@"feature"];
    [coder encodeObject:self.stage forKey:@"stage"];
    [coder encodeObject:[LMEncodingUtils encodeDictionaryToJsonString:self.params] forKey:@"params"];
}

@end
