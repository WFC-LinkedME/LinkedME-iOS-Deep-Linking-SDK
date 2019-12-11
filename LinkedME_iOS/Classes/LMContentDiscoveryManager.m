//
//  LMContentDiscoveryManager.m
//  iOS-Deep-Linking-SDK
//
//  Created on 7/17/15.
//  Copyright © 2015 Bindx. All rights reserved.
//

#import "LMContentDiscoveryManager.h"
#import "LMSystemObserver.h"
#import "LMError.h"
#import "LMConstants.h"

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreSpotlight/CoreSpotlight.h>
#endif

#ifndef kUTTypeGeneric
#define kUTTypeGeneric @"public.content"
#endif

#ifndef CSSearchableItemActionType
#define CSSearchableItemActionType @"com.apple.corespotlightitem"
#endif

#ifndef CSSearchableItemActivityIdentifier
#define CSSearchableItemActivityIdentifier @"kCSSearchableItemActivityIdentifier"
#endif

@interface LMContentDiscoveryManager ()

@property (strong, nonatomic) NSUserActivity *currentUserActivity;

@end

@implementation LMContentDiscoveryManager

#pragma mark - Launch handling

- (NSString *)spotlightIdentifierFromActivity:(NSUserActivity *)userActivity {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    //检测是否有前缀 LINKEDME_SPOTLIGHT_PREFIX
//    if ([userActivity.activityType hasPrefix:LINKEDME_SPOTLIGHT_PREFIX]) {
//        return userActivity.activityType;
//    }
    if (userActivity.activityType.length >0) {
        return userActivity.activityType;
    }
    
    // CoreSpotlight version. Matched if it has our prefix, then the link identifier is just the last piece of the identifier.
    if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
        NSString *activityIdentifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
        BOOL isLinkedMEIdentifier = [activityIdentifier hasPrefix:LINKEDME_SPOTLIGHT_PREFIX];
        
        if (isLinkedMEIdentifier) {
            return activityIdentifier;
        }
    }
#endif
    return nil;
}

- (NSString *)standardSpotlightIdentifierFromActivity:(NSUserActivity *)userActivity {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    // CoreSpotlight version. Matched if it has our prefix, then the link identifier is just the last piece of the identifier.
    if ([userActivity.activityType isEqualToString:CSSearchableItemActionType] && userActivity.userInfo[CSSearchableItemActivityIdentifier]) {
        return userActivity.userInfo[CSSearchableItemActivityIdentifier];
    }
#endif
    
    return nil;
}


#pragma mark - Content Indexing

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
          spotlightIdentifier:(NSString *)identifier
                     callback:(callbackWithUrl)callback {
    
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
            spotlightIdentifier:identifier
                       callback:callback
              spotlightCallback:nil];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
          spotlightIdentifier:(NSString *)identifier
            spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
    
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
            spotlightIdentifier:identifier
                       callback:nil
              spotlightCallback:spotlightCallback];
}

//This is the final one, which figures out which callback to use, if any
// The simpler callbackWithURL overrides spotlightCallback, so don't send both
- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
               expirationDate:(NSDate *)expirationDate
          spotlightIdentifier:(NSString *)identifier
                     callback:(callbackWithUrl)callback
            spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {

    if ([LMSystemObserver getOSVersion].integerValue < 9) {
        NSError *error = [NSError errorWithDomain:LMErrorDomain code:LKMEVersionError userInfo:@{ NSLocalizedDescriptionKey: @"CoreSpotlight不可用,因为这个项目的基与SDK 9.0" }];
        if (callback) {
            callback(nil, error);
        }
        else if (spotlightCallback) {
            spotlightCallback(nil, nil, error);
        }
        return;
    }
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
    NSError *error = [NSError errorWithDomain:LKMEErrorDomain code:LKMEBadRequestError userInfo:@{ NSLocalizedDescriptionKey: @"CoreSpotlight不可用,因为这个项目的基与SDK 9.0" }];
    if (callback) {
        callback(nil, error);
    }
    else if (spotlightCallback) {
        spotlightCallback(nil, nil, error);
    }
    return;
#endif
    BOOL isIndexingAvailable = NO;
    /*
     BUG描述："主工程(MainProject)"调"静态库工程(LibProject)"的方法实例化对象，目标类存在于LibProject中，通过NSClassFromString实例化无法获取实例对象
     参考链接：http://stackoverflow.com/questions/2227085/nsclassfromstring-returns-nil
     解决方案：1.在Other Lind Flag中添加 “-all_load”，
             2.使用[xxx class]获取对象
     */
//        Class CSSearchableIndexClass = NSClassFromString(@"CSSearchableIndex");
//        SEL isIndexingAvailableSelector = NSSelectorFromString(@"isIndexingAvailable");
    
    //    Class class = object_getClass((id)self);
        Class CSSearchableIndexClass = [CSSearchableIndex class];
        SEL isIndexingAvailableSelector = @selector(isIndexingAvailable);
    
        isIndexingAvailable = ((BOOL (*)(id, SEL))[CSSearchableIndexClass methodForSelector:isIndexingAvailableSelector])(CSSearchableIndexClass, isIndexingAvailableSelector);

//    Class CSSearchableIndexClassx = [CSSearchableIndex class];
//    SEL loadSelector = @selector(isIndexingAvailable);
//    SEL loadingSelector = @selector(CustomLoad);
    
    if (!isIndexingAvailable) {
        NSError *error = [NSError errorWithDomain:LMErrorDomain code:LKMEVersionError userInfo:@{ NSLocalizedDescriptionKey: @"Spotlight无法在当前设备上运行" }];
        if (callback) {
            callback(nil, error);
        }
        else if (spotlightCallback) {
            spotlightCallback(nil, nil, error);
        }
        return;
    }
    if (!title) {
        NSError *error = [NSError errorWithDomain:LMErrorDomain code:LKMEBadRequestError userInfo:@{ NSLocalizedDescriptionKey: @"Spotlight标题未填写" }];
        if (callback) {
            callback(nil, error);
        }
        else if (spotlightCallback) {
            spotlightCallback(nil, nil, error);
        }
        return;
    }
    
    //类型不能为空
    NSString *typeOrDefault = type ?: (NSString *)kUTTypeGeneric;
    
    //必要参数
    NSMutableDictionary *spotlightLinkData = [[NSMutableDictionary alloc] init];
    spotlightLinkData[LINKEDME_LINK_DATA_KEY_TITLE] = title;
    spotlightLinkData[LINKEDME_LINK_DATA_KEY_PUBLICLY_INDEXABLE] = @(publiclyIndexable);
    spotlightLinkData[LINKEDME_LINK_DATA_KEY_TYPE] = typeOrDefault;
    
    

    
    if (userInfo) {
        [spotlightLinkData addEntriesFromDictionary:
             @{@"controlParams": userInfo}
         ];
    }
    
    //设置标题
    if (!spotlightLinkData[LINKEDME_LINK_DATA_KEY_OG_TITLE]) {
        spotlightLinkData[LINKEDME_LINK_DATA_KEY_OG_TITLE] = title;
    }
    
    //设置描述
    if (description) {
        spotlightLinkData[LINKEDME_LINK_DATA_KEY_DESCRIPTION] = description;
        if (!spotlightLinkData[LINKEDME_LINK_DATA_KEY_OG_DESCRIPTION]) {
            spotlightLinkData[LINKEDME_LINK_DATA_KEY_OG_DESCRIPTION] = description;
        }
    }
    
    NSString *thumbnailUrlString = [thumbnailUrl absoluteString];
    BOOL thumbnailIsRemote = thumbnailUrl && ![thumbnailUrl isFileURL];
    if (thumbnailUrlString) {
        spotlightLinkData[LINKEDME_LINK_DATA_KEY_THUMBNAIL_URL] = thumbnailUrlString;
        
        // 设置远程图片地址
        if (thumbnailIsRemote && !spotlightLinkData[LINKEDME_LINK_DATA_KEY_OG_IMAGE_URL]) {
            spotlightLinkData[LINKEDME_LINK_DATA_KEY_OG_IMAGE_URL] = thumbnailUrlString;
        }
    }
    
    //设置identifier
    if (identifier) {
        spotlightLinkData[LINKEDME_LINK_DATA_SPOTLIGHTIDENTIFIER] = identifier;
        if (!spotlightLinkData[LINKEDME_LINK_DATA_SPOTLIGHTIDENTIFIER]) {
            spotlightLinkData[LINKEDME_LINK_DATA_SPOTLIGHTIDENTIFIER] = identifier;
        }
    }
    
    //设置关键字
    if (keywords) {
        spotlightLinkData[LINKEDME_LINK_DATA_KEY_KEYWORDS] = [keywords allObjects];
    }
    
    [[LinkedME getInstance] getSpotlightUrlWithParams:spotlightLinkData callback:^(NSDictionary *data, NSError *urlError) {
        
        
        if (urlError){
            if (callback) {
                callback(nil, urlError);
            }
            else if (spotlightCallback) {
                spotlightCallback(nil, nil, urlError);
            }

            return;
        }
        
        if (thumbnailIsRemote) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *thumbnailData = [NSData dataWithContentsOfURL:thumbnailUrl];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self indexContentWithUrl:data[LINKEDME_RESPONSE_KEY_URL] spotlightIdentifier:identifier title:title description:description type:typeOrDefault thumbnailUrl:thumbnailUrl thumbnailData:thumbnailData publiclyIndexable:publiclyIndexable userInfo:userInfo keywords:keywords expirationDate:expirationDate callback:callback spotlightCallback:spotlightCallback];
                });
            });
        }
        else {
            [self indexContentWithUrl:data[LINKEDME_RESPONSE_KEY_URL] spotlightIdentifier:identifier title:title description:description type:typeOrDefault thumbnailUrl:thumbnailUrl thumbnailData:nil publiclyIndexable:publiclyIndexable userInfo:userInfo keywords:keywords expirationDate:expirationDate callback:callback spotlightCallback:spotlightCallback];
        }
    }];
}

- (void)indexContentWithUrl:(NSString *)url spotlightIdentifier:(NSString *)spotlightIdentifier title:(NSString *)title description:(NSString *)description type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl thumbnailData:(NSData *)thumbnailData publiclyIndexable:(BOOL)publiclyIndexable userInfo:(NSDictionary *)userInfo keywords:(NSSet *)keywords expirationDate:(NSDate *)expirationDate callback:(callbackWithUrl)callback spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    
    id CSSearchableItemAttributeSetClass = NSClassFromString(@"CSSearchableItemAttributeSet");
    id attributes = [CSSearchableItemAttributeSetClass alloc];
    SEL initAttributesSelector = NSSelectorFromString(@"initWithItemContentType:");
    attributes = ((id (*)(id, SEL, NSString *))[attributes methodForSelector:initAttributesSelector])(attributes, initAttributesSelector, type);
    SEL setIdentifierSelector = NSSelectorFromString(@"setIdentifier:");
    ((void (*)(id, SEL, NSString *))[attributes methodForSelector:setIdentifierSelector])(attributes, setIdentifierSelector, spotlightIdentifier);
    SEL setRelatedUniqueIdentifierSelector = NSSelectorFromString(@"setRelatedUniqueIdentifier:");
    ((void (*)(id, SEL, NSString *))[attributes methodForSelector:setRelatedUniqueIdentifierSelector])(attributes, setRelatedUniqueIdentifierSelector, spotlightIdentifier);
    SEL setTitleSelector = NSSelectorFromString(@"setTitle:");
    ((void (*)(id, SEL, NSString *))[attributes methodForSelector:setTitleSelector])(attributes, setTitleSelector, title);
    SEL setContentDescriptionSelector = NSSelectorFromString(@"setContentDescription:");
    ((void (*)(id, SEL, NSString *))[attributes methodForSelector:setContentDescriptionSelector])(attributes, setContentDescriptionSelector, description);
    SEL setThumbnailURLSelector = NSSelectorFromString(@"setThumbnailURL:");
    ((void (*)(id, SEL, NSURL *))[attributes methodForSelector:setThumbnailURLSelector])(attributes, setThumbnailURLSelector, thumbnailUrl);
    SEL setThumbnailDataSelector = NSSelectorFromString(@"setThumbnailData:");
    ((void (*)(id, SEL, NSData *))[attributes methodForSelector:setThumbnailDataSelector])(attributes, setThumbnailDataSelector, thumbnailData);
    SEL setContentURLSelector = NSSelectorFromString(@"setContentURL:");
    ((void (*)(id, SEL, NSURL *))[attributes methodForSelector:setContentURLSelector])(attributes, setContentURLSelector, [NSURL URLWithString:url]);
    
    // Index via the NSUserActivity strategy
    // Currently (iOS 9 Beta 4) we need a strong reference to this, or it isn't indexed
    self.currentUserActivity = [[NSUserActivity alloc] initWithActivityType:spotlightIdentifier];
    self.currentUserActivity.title = title;
    self.currentUserActivity.webpageURL = [NSURL URLWithString:url];
    // This should allow indexed content to fall back to the web if user doesn't have the app installed. Unable to test as of iOS 9 Beta 4
    self.currentUserActivity.eligibleForSearch = YES;
    self.currentUserActivity.eligibleForPublicIndexing = publiclyIndexable;
    SEL setContentAttributeSetSelector = NSSelectorFromString(@"setContentAttributeSet:");
    ((void (*)(id, SEL, id))[self.currentUserActivity methodForSelector:setContentAttributeSetSelector])(self.currentUserActivity, setContentAttributeSetSelector, attributes);
    self.currentUserActivity.userInfo = userInfo;
    // As of iOS 9 Beta 4, this gets lost and never makes it through to application:continueActivity:restorationHandler:
    self.currentUserActivity.requiredUserInfoKeys = [NSSet setWithArray:userInfo.allKeys];
    // This, however, seems to force the userInfo to come through.
    self.currentUserActivity.keywords = keywords;
    [self.currentUserActivity becomeCurrent];
    
    // Index via the CoreSpotlight strategy
    //get the CSSearchableItem Class object
    id CSSearchableItemClass = NSClassFromString(@"CSSearchableItem");
    //alloc an empty instance
    id searchableItem = [CSSearchableItemClass alloc];
    //create-by-name a selector fot the init method we want
    SEL initItemSelector = NSSelectorFromString(@"initWithUniqueIdentifier:domainIdentifier:attributeSet:");
    //call the selector on the searchableItem with appropriate arguments
    searchableItem = ((id (*)(id, SEL, NSString *, NSString *, id))[searchableItem methodForSelector:initItemSelector])(searchableItem, initItemSelector, spotlightIdentifier, LINKEDME_SPOTLIGHT_PREFIX, attributes);
    
    //创建expirationSelector方法选择器设置Spotlight索引失效时间
    SEL expirationSelector = NSSelectorFromString(@"setExpirationDate:");
    //now invoke it on the searchableItem, providing the expirationdate
    ((void (*)(id, SEL, NSDate *))[searchableItem methodForSelector:expirationSelector])(searchableItem, expirationSelector, expirationDate);
    
    //打包成SDK后通过NSClassFromString获取类可能会出现异常
//    Class CSSearchableIndexClass = NSClassFromString(@"CSSearchableIndex");
    Class CSSearchableIndexClass = [CSSearchableIndex class];

    SEL defaultSearchableIndexSelector = NSSelectorFromString(@"defaultSearchableIndex");
    id defaultSearchableIndex = ((id (*)(id, SEL))[CSSearchableIndexClass methodForSelector:defaultSearchableIndexSelector])(CSSearchableIndexClass, defaultSearchableIndexSelector);
    SEL indexSearchableItemsSelector = NSSelectorFromString(@"indexSearchableItems:completionHandler:");
    void (^__nullable completionBlock)(NSError *indexError) = ^void(NSError *__nullable indexError) {
        if (callback || spotlightCallback) {
            if (indexError) {
                if (callback) {
                    callback(nil, indexError);
                }
                else if (spotlightCallback) {
                    spotlightCallback(nil, nil, indexError);
                }
            }
            else {
                if (callback) {
                    callback(url, nil);
                }
                else if (spotlightCallback) {
                    spotlightCallback(url, spotlightIdentifier, nil);
                }
            }
        }
    };
    ((void (*)(id, SEL, NSArray *, void (^ __nullable)(NSError * __nullable error)))[defaultSearchableIndex methodForSelector:indexSearchableItemsSelector])(defaultSearchableIndex, indexSearchableItemsSelector, @[searchableItem], completionBlock);
#endif
}


@end
