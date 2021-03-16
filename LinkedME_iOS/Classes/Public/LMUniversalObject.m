//
//  LMUniversalObject.m
//  iOS-Deep-Linking-SDK
//
//  Created on 10/16/15.
//  Copyright © 2015 Bindx. All rights reserved.
//

#import "LMError.h"
#import "LMConstants.h"
#import "LMUniversalObject.h"

@implementation LMUniversalObject

- (instancetype)initWithCanonicalIdentifier:(NSString*)canonicalIdentifier{
    if (self = [super init]) {
        self.canonicalIdentifier = canonicalIdentifier;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString*)title{
    if (self = [super init]) {
        self.title = title;
    }
    return self;
}

- (NSDictionary*)metadata{
    if (!_metadata) {
        _metadata = [[NSDictionary alloc] init];
    }
    return _metadata;
}

- (void)addMetadataKey:(NSString*)key value:(NSString*)value{
    if (!key || !value) {
        return;
    }
    NSMutableDictionary* temp = [self.metadata mutableCopy];
    temp[key] = value;
    _metadata = [temp copy];
}

- (void)registerView{
    if (!self.canonicalIdentifier && !self.title) {
        NSLog(@"[LinkedME Warning] a canonicalIdentifier or title are required to "
              @"uniquely identify content, so could not register view.");
        return;
    }

    [[LinkedME getInstance] registerViewWithParams:[self getParamsForServerRequest]
                                     andCallback:nil];
}

- (void)registerViewWithCallback:(callbackWithParams)callback{
    if (!self.canonicalIdentifier && !self.title) {
        if (callback) {
            callback(nil,
                [NSError errorWithDomain:LMErrorDomain
                                    code:LKMEInitError
                                userInfo:@{
                                    NSLocalizedDescriptionKey :
                                        @"A canonicalIdentifier or title are "
                                        @"required to uniquely identify content, "
                                        @"so could not register view."
                                }]);
        }
        else {
            NSLog(@"[LinkedME Warning] a canonicalIdentifier or title are required to "
                  @"uniquely identify content, so could not register view.");
        }
        return;
    }

    [[LinkedME getInstance] registerViewWithParams:[self getParamsForServerRequest]
                                     andCallback:callback];
}

#pragma mark - Link Creation Methods

- (NSString*)getShortUrlWithLinkProperties:(LMLinkProperties*)linkProperties{
    if (!self.canonicalIdentifier && !self.title) {
        NSLog(@"[LinkedME Warning] a canonicalIdentifier or title are required to "
              @"uniquely identify content, so could not generate a URL.");
        return nil;
    }
    
    [[LinkedME getInstance] getShortUrlWithParams:
     
//     [self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
     
     [self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
                                            andTags:linkProperties.tags
                                           andAlias:linkProperties.alias
                                   andMatchDuration:linkProperties.matchDuration
                                         andChannel:linkProperties.channel
                                         andFeature:linkProperties.feature
                                           andStage:linkProperties.stage
                                           andState:linkProperties.state
                                        andCallback:nil];

    return @"";
}

- (void)getShortUrlWithLinkProperties:(LMLinkProperties*)linkProperties
                          andCallback:(callbackWithUrl)callback{
    if (!self.canonicalIdentifier && !self.title) {
        if (callback) {
            callback(nil,
                [NSError errorWithDomain:LMErrorDomain
                                    code:LKMEInitError
                                userInfo:@{
                                    NSLocalizedDescriptionKey :
                                        @"A canonicalIdentifier or title are "
                                        @"required to uniquely identify content, "
                                        @"so could not generate a URL."
                                }]);
        }
        else {
            NSLog(@"[LinkedME Warning] a canonicalIdentifier or title are required to "
                  @"uniquely identify content, so could not generate a URL.");
        }
        return;
    }

      [[LinkedME getInstance] getShortUrlWithParams:
       
                              [self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
                      andTags:linkProperties.tags
                     andAlias:linkProperties.alias
             andMatchDuration:linkProperties.matchDuration
                   andChannel:linkProperties.channel
                   andFeature:linkProperties.feature
                     andStage:linkProperties.stage
                     andState:linkProperties.state
                   andCallback:callback];
}

- (void)listOnSpotlight
{
    [self listOnSpotlightWithCallback:nil];
}

- (void)listOnSpotlightWithCallback:(callbackWithUrl)callback
{
    BOOL publiclyIndexable;
    if (self.contentIndexMode == ContentIndexModePrivate) {
        publiclyIndexable = NO;
    }
    else {
        publiclyIndexable = YES;
    }

    NSMutableDictionary* metadataAndProperties = [self.metadata mutableCopy];
    if (self.canonicalIdentifier) {
        metadataAndProperties[LINKEDME_LINK_DATA_KEY_CANONICAL_IDENTIFIER] = self.canonicalIdentifier;
    }
    if (self.canonicalUrl) {
        metadataAndProperties[LINKEDME_LINK_DATA_KEY_CANONICAL_URL] = self.canonicalUrl;
    }

    [[LinkedME getInstance]
        createDiscoverableContentWithTitle:self.title
                               description:self.contentDescription
                              thumbnailUrl:[NSURL URLWithString:self.imageUrl]
                                linkParams:metadataAndProperties.copy
                                      type:self.type
                         publiclyIndexable:publiclyIndexable
                                  keywords:[NSSet setWithArray:self.keywords]
                            expirationDate:self.expirationDate
                       spotlightIdentifier:self.spotlightIdentifier
                                  callback:callback];
}

// This one uses a callback that returns the SpotlightIdentifier
- (void)listOnSpotlightWithIdentifierCallback:
    (callbackWithUrlAndSpotlightIdentifier)spotlightCallback
{
    BOOL publiclyIndexable;
    if (self.contentIndexMode == ContentIndexModePrivate) {
        publiclyIndexable = NO;
    }
    else {
        publiclyIndexable = YES;
    }

    NSMutableDictionary* metadataAndProperties = [self.metadata mutableCopy];
    if (self.canonicalIdentifier) {
        metadataAndProperties[LINKEDME_LINK_DATA_KEY_CANONICAL_IDENTIFIER] = self.canonicalIdentifier;
    }
    if (self.canonicalUrl) {
        metadataAndProperties[LINKEDME_LINK_DATA_KEY_CANONICAL_URL] = self.canonicalUrl;
    }

#warning 修改
    [[LinkedME getInstance]
        createDiscoverableContentWithTitle:self.title
                               description:self.contentDescription
                              thumbnailUrl:[NSURL URLWithString:self.imageUrl]
                                linkParams:metadataAndProperties.copy
                                      type:self.type
                         publiclyIndexable:publiclyIndexable
                                  keywords:[NSSet setWithArray:self.keywords]
                            expirationDate:self.expirationDate
                       spotlightIdentifier:self.spotlightIdentifier
                         spotlightCallback:spotlightCallback];
}

+ (LMUniversalObject*)getLinkedMEUniversalObjectFromDictionary:
    (NSDictionary*)dictionary
{
    LMUniversalObject* universalObject = [[LMUniversalObject alloc] init];

    
    universalObject.metadata = [dictionary copy];
    if (dictionary[LINKEDME_LINK_DATA_KEY_CANONICAL_IDENTIFIER]) {
        universalObject.canonicalIdentifier = dictionary[LINKEDME_LINK_DATA_KEY_CANONICAL_IDENTIFIER];
    }
    if (dictionary[LINKEDME_LINK_DATA_KEY_CANONICAL_URL]) {
        universalObject.canonicalUrl = dictionary[LINKEDME_LINK_DATA_KEY_CANONICAL_URL];
    }
    if (dictionary[LINKEDME_LINK_DATA_KEY_OG_TITLE]) {
        universalObject.title = dictionary[LINKEDME_LINK_DATA_KEY_OG_TITLE];
    }
    if (dictionary[LINKEDME_LINK_DATA_KEY_OG_DESCRIPTION]) {
        universalObject.contentDescription = dictionary[LINKEDME_LINK_DATA_KEY_OG_DESCRIPTION];
    }
    if (dictionary[LINKEDME_LINK_DATA_KEY_OG_IMAGE_URL]) {
        universalObject.imageUrl = dictionary[LINKEDME_LINK_DATA_KEY_OG_IMAGE_URL];
    }
    if (dictionary[LINKEDME_LINK_DATA_KEY_PUBLICLY_INDEXABLE]) {
        if (dictionary[LINKEDME_LINK_DATA_KEY_PUBLICLY_INDEXABLE] == 0) {
            universalObject.contentIndexMode = ContentIndexModePrivate;
        }
        else {
            universalObject.contentIndexMode = ContentIndexModePublic;
        }
    }

    if (dictionary[LINKEDME_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE] &&
        [dictionary[LINKEDME_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE]
            isKindOfClass:[NSNumber class]]) {
        NSNumber* millisecondsSince1970 = dictionary[LINKEDME_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE];
        universalObject.expirationDate = [NSDate
            dateWithTimeIntervalSince1970:millisecondsSince1970.integerValue / 1000];
    }
    if (dictionary[LINKEDME_LINK_DATA_KEY_KEYWORDS]) {
        universalObject.keywords = dictionary[LINKEDME_LINK_DATA_KEY_KEYWORDS];
    }

    return universalObject;
}

- (NSString*)description
{
    return [NSString
        stringWithFormat:@"LinkedMEUniversalObject \n canonicalIdentifier: %@ \n "
                         @"title: %@ \n contentDescription: %@ \n imageUrl: %@ "
                         @"\n metadata: %@ \n type: %@ \n contentIndexMode: %ld "
                         @"\n keywords: %@ \n expirationDate: %@",
        self.canonicalIdentifier, self.title,
        self.contentDescription, self.imageUrl, self.metadata,
        self.type, (long)self.contentIndexMode, self.keywords,
        self.expirationDate];
}

#pragma mark - Private methods

- (NSDictionary*)getParamsForServerRequest
{
    NSMutableDictionary* temp = [[NSMutableDictionary alloc] init];
    //新增Spotlight数据
    [self safeSetValue:self.spotlightIdentifier
                forKey:LINKEDME_LINK_DATA_SPOTLIGHTIDENTIFIER
                onDict:temp];
    
    [self safeSetValue:self.canonicalIdentifier
                forKey:LINKEDME_LINK_DATA_KEY_CANONICAL_IDENTIFIER
                onDict:temp];
    [self safeSetValue:self.canonicalUrl
                forKey:LINKEDME_LINK_DATA_KEY_CANONICAL_URL
                onDict:temp];
    [self safeSetValue:self.title
                forKey:LINKEDME_LINK_DATA_KEY_OG_TITLE
                onDict:temp];
    [self safeSetValue:self.contentDescription
                forKey:LINKEDME_LINK_DATA_KEY_OG_DESCRIPTION
                onDict:temp];
    [self safeSetValue:self.imageUrl
                forKey:LINKEDME_LINK_DATA_KEY_OG_IMAGE_URL
                onDict:temp];
    if (self.contentIndexMode == ContentIndexModePrivate) {
        [self safeSetValue:@(0)
                    forKey:LINKEDME_LINK_DATA_KEY_PUBLICLY_INDEXABLE
                    onDict:temp];
    }else {
        [self safeSetValue:@(1)
                    forKey:LINKEDME_LINK_DATA_KEY_PUBLICLY_INDEXABLE
                    onDict:temp];
    }
    [self safeSetValue:self.keywords
                forKey:LINKEDME_LINK_DATA_KEY_KEYWORDS
                onDict:temp];
    [self safeSetValue:@(1000 * [self.expirationDate timeIntervalSince1970])
                forKey:LINKEDME_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE
                onDict:temp];
    [self safeSetValue:self.type
                forKey:LINKEDME_LINK_DATA_KEY_CONTENT_TYPE
                onDict:temp];

    //    [temp addEntriesFromDictionary:[self.metadata copy]];

    [self safeSetValue:self.metadata
                forKey:LINKEDME_LINK_DATA_KEY_METADATA
                onDict:temp];

    return [temp copy];
}

- (NSDictionary*)getParamsForServerRequestWithAddedLinkProperties:
    (LMLinkProperties*)linkProperties{
    NSMutableDictionary* temp = [[self getParamsForServerRequest] mutableCopy];
    [self safeSetValue:linkProperties.controlParams
                forKey:LINKEDME_LINK_DATA_KEY_CONTROL
                onDict:temp];
    return [temp copy];
}

- (void)safeSetValue:(NSObject*)value
              forKey:(NSString*)key
              onDict:(NSMutableDictionary*)dict{
    if (value) {
        dict[key] = value;
    }
}

@end
