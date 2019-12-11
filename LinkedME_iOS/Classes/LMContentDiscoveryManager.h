//
//  LMContentDiscoveryManager.h
//  iOS-Deep-Linking-SDK
//
//  Created on 7/17/15.
//  Copyright © 2015 Bindx. All rights reserved.
//

#import "LinkedME.h"

//发现内容管理

@interface LMContentDiscoveryManager : NSObject

//从spotlight获取内容
- (NSString *)spotlightIdentifierFromActivity:(NSUserActivity *)userActivity;
- (NSString *)standardSpotlightIdentifierFromActivity:(NSUserActivity *)userActivity;

#pragma mark - 创建Spotlight索引

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl keywords:(NSSet *)keywords userInfo:(NSDictionary *)userInfo spotlightIdentifier:(NSString *)identifier callback:(callbackWithUrl)callback;


- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl keywords:(NSSet *)keywords userInfo:(NSDictionary *)userInfo spotlightIdentifier:(NSString *)identifier spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback;


/* This one has a different callback, which includes the spotlightIdentifier, and requires a different signature
    It cannot be part of the stack of method signatures above, because of the different callback type.*/

/**
 *   创建Spotlight索引
 *
 *  @param title             标题
 *  @param description       描述
 *  @param publiclyIndexable 是否公开
 *  @param type              类型
 *  @param thumbnailUrl      缩略图Url
 *  @param keywords          关键字
 *  @param userInfo          用户详情
 *  @param expirationDate    截止日期
 *  @param identifier        标志符
 *  @param callback          回调
 *  @param spotlightCallback Spotlight回掉
 */
- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl keywords:(NSSet *)keywords userInfo:(NSDictionary *)userInfo expirationDate:(NSDate *)expirationDate spotlightIdentifier:(NSString *)identifier callback:(callbackWithUrl)callback spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback;

@end
