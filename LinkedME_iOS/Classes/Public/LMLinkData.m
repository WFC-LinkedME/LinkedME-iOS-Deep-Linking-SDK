//
//  LMLinkData.m
//  iOS-Deep-Linking-SDK
//
//  Created on 1/22/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMEncodingUtils.h"
#import "LMLinkData.h"
#import "LMConstants.h"

@interface LMLinkData ()

@property (strong, nonatomic) NSArray* tags;
@property (strong, nonatomic) NSString* alias;
@property (strong, nonatomic) NSString* channel;
@property (strong, nonatomic) NSString* feature;
@property (strong, nonatomic) NSString* stage;
@property (strong, nonatomic) NSDictionary* params;
@property (strong, nonatomic) NSString* ignoreUAString;
@property (assign, nonatomic) LMLinkType type;
@property (assign, nonatomic) NSUInteger duration;

@end

@implementation LMLinkData

- (id)init{
    if (self = [super init]) {
        self.data = [[NSMutableDictionary alloc] init];
        self.data[@"source"] = @"iOS";
    }
    return self;
}

- (void)setupTags:(NSArray*)tags{
    if (tags) {
        _tags = tags;

//        self.data[LINKEDME_REQUEST_KEY_URL_TAGS] = tags;
        self.data[LINKEDME_REQUEST_KEY_URL_TAGS] = [tags componentsJoinedByString:@","];
    }
}

- (void)setupAlias:(NSString*)alias
{
    if (alias) {
        _alias = alias;
        self.data[LINKEDME_REQUEST_KEY_URL_ALIAS] = alias;
    }
}

- (void)setupType:(LMLinkType)type
{
    if (type) {
        _type = type;
        self.data[LINKEDME_REQUEST_KEY_URL_LINK_TYPE] = @(type);
    }
}

- (void)setupMatchDuration:(NSUInteger)duration
{
    if (duration > 0) {
        _duration = duration;
        self.data[LINKEDME_REQUEST_KEY_URL_DURATION] = @(duration);
    }
}

- (void)setupChannel:(NSString*)channel
{
    if (channel) {
        _channel = channel;
        NSMutableArray *channelArr = [NSMutableArray array];
        [channelArr addObject:channel];
        self.data[LINKEDME_REQUEST_KEY_URL_CHANNEL] = channel;
//        self.data[LINKEDME_REQUEST_KEY_URL_CHANNEL] = channelArr;
    }
}

- (void)setupFeature:(NSString*)feature
{
    if (feature) {
        _feature = feature;
        NSMutableArray *featureArr = [NSMutableArray array];
        [featureArr addObject:feature];
        self.data[LINKEDME_REQUEST_KEY_URL_FEATURE] = feature;
//        self.data[LINKEDME_REQUEST_KEY_URL_FEATURE] = featureArr;
    }
}

- (void)setupStage:(NSString*)stage
{
    if (stage) {
        _stage = stage;
        NSMutableArray *stageArr = [NSMutableArray array];
        [stageArr addObject:stage];
        self.data[LINKEDME_REQUEST_KEY_URL_STAGE] = stage;
    }
}

- (void)setupIgnoreUAString:(NSString*)ignoreUAString
{
    if (ignoreUAString) {
        _ignoreUAString = ignoreUAString;

        self.data[LINKEDME_REQUEST_KEY_URL_IGNORE_UA_STRING] = ignoreUAString;
    }
}

- (void)setupParams:(NSDictionary*)params{
    if (params) {
        
        _params = params;
        
        self.data[LKME_REQUEST_KEY_URL_DATA] = [self DataTOjsonString:params];
        
        NSLog(@"%@",[self DataTOjsonString:params]);
    }
}

-(NSString*)DataTOjsonString:(id)object{
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:0
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}


- (NSUInteger)hash{
    NSUInteger result = 1;
    NSUInteger prime = 19;

    NSString* encodedParams = [LMEncodingUtils encodeDictionaryToJsonString:self.params];
    result = prime * result + self.type;
    result = prime * result + [[LMEncodingUtils md5Encode:self.alias] hash];
    result = prime * result + [[LMEncodingUtils md5Encode:self.channel] hash];
    result = prime * result + [[LMEncodingUtils md5Encode:self.feature] hash];
    result = prime * result + [[LMEncodingUtils md5Encode:self.stage] hash];
    result = prime * result + [[LMEncodingUtils md5Encode:encodedParams] hash];
    result = prime * result + self.duration;

    for (NSString* tag in self.tags) {
        result = prime * result + [[LMEncodingUtils md5Encode:tag] hash];
    }

    return result;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    if (self.tags) {
        [coder encodeObject:self.tags forKey:LINKEDME_REQUEST_KEY_URL_TAGS];
    }
    if (self.alias) {
        [coder encodeObject:self.alias forKey:LINKEDME_REQUEST_KEY_URL_ALIAS];
    }
    if (self.type) {
        [coder encodeObject:@(self.type) forKey:LINKEDME_REQUEST_KEY_URL_LINK_TYPE];
    }
    if (self.channel) {
        [coder encodeObject:self.channel forKey:LINKEDME_REQUEST_KEY_URL_CHANNEL];
    }
    if (self.feature) {
        [coder encodeObject:self.feature forKey:LINKEDME_REQUEST_KEY_URL_FEATURE];
    }
    if (self.stage) {
        [coder encodeObject:self.stage forKey:LINKEDME_REQUEST_KEY_URL_STAGE];
    }
    if (self.params) {
        NSString* encodedParams = [LMEncodingUtils encodeDictionaryToJsonString:self.params];
        [coder encodeObject:encodedParams forKey:LINKEDME_REQUEST_KEY_URL_DATA];
    }
    if (self.duration > 0) {
        [coder encodeObject:@(self.duration) forKey:LINKEDME_REQUEST_KEY_URL_DURATION];
    }
}

- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init]) {
        self.tags = [coder decodeObjectForKey:LINKEDME_REQUEST_KEY_URL_TAGS];
        self.alias = [coder decodeObjectForKey:LINKEDME_REQUEST_KEY_URL_ALIAS];
        self.type = [[coder decodeObjectForKey:LINKEDME_REQUEST_KEY_URL_LINK_TYPE] integerValue];
        self.channel = [coder decodeObjectForKey:LINKEDME_REQUEST_KEY_URL_CHANNEL];
        self.feature = [coder decodeObjectForKey:LINKEDME_REQUEST_KEY_URL_FEATURE];
        self.stage = [coder decodeObjectForKey:LINKEDME_REQUEST_KEY_URL_STAGE];
        self.duration = [[coder decodeObjectForKey:LINKEDME_REQUEST_KEY_URL_DURATION] integerValue];
        NSString* encodedParams = [coder decodeObjectForKey:LINKEDME_REQUEST_KEY_URL_DATA];
        self.params = [LMEncodingUtils decodeJsonStringToDictionary:encodedParams];
    }

    return self;
}

@end
