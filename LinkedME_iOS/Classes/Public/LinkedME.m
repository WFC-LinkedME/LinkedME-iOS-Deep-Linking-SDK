//
//  LKME_SDK.m
//  LKME-SDK
//  iOS-Deep-Linking-SDK

//  Created on 6/5/14.
//  Copyright (c) 2014 LKME  All rights reserved.
//

#import "LKMEConfig.h"
#import "LMContentDiscoveryManager.h"
#import "LMEncodingUtils.h"
#import "LMError.h"
#import "LMLinkCache.h"
#import "LMLinkData.h"
#import "LMPreferenceHelper.h"
#import "LMServerRequest.h"
#import "LMServerRequestQueue.h"
#import "LMServerResponse.h"
#import "LMStrongMatchHelper.h"
#import "LMSystemObserver.h"
#import "LinkedME.h"
#import "LMCloseRequest.h"
#import "LMInstallRequest.h"
#import "LMLoadRewardsRequest.h"
#import "LMLogoutRequest.h"
#import "LMOpenRequest.h"
#import "LMRegisterViewRequest.h"
#import "LMSetIdentityRequest.h"
#import "LMShortUrlRequest.h"
#import "LMSpotlightUrlRequest.h"
#import "LMUniversalObject.h"
#import "LMConstants.h"
#import "LKMEConfig.h"
#import <StoreKit/StoreKit.h>
#import "LMAppConnect.h"
#import <WebKit/WebKit.h>
#import "LMLinkProperties.h"
#import<CoreTelephony/CTCellularData.h>
#import <objc/runtime.h>

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
#import <CoreSpotlight/CoreSpotlight.h>
#endif



NSString *const LINKEDME_FEATURE_TAG_SHARE = @"share";
NSString *const LINKEDME_FEATURE_TAG_REFERRAL = @"referral";
NSString *const LINKEDME_FEATURE_TAG_INVITE = @"invite";
NSString *const LINKEDME_FEATURE_TAG_DEAL = @"deal";
NSString *const LINKEDME_FEATURE_TAG_GIFT = @"gift";

NSString *const LINKEDME_INIT_KEY_CHANNEL = @"~channel";
NSString *const LINKEDME_INIT_KEY_FEATURE = @"~feature";
NSString *const LINKEDME_INIT_KEY_TAGS = @"~tags";
NSString *const LINKEDME_INIT_KEY_CAMPAIGN = @"~campaign";
NSString *const LINKEDME_INIT_KEY_STAGE = @"~stage";
NSString *const LINKEDME_INIT_KEY_CREATION_SOURCE = @"~creation_source";
NSString *const LINKEDME_INIT_KEY_REFERRER = @"+referrer";
NSString *const LINKEDME_INIT_KEY_PHONE_NUMBER = @"+phone_number";
NSString *const LINKEDME_INIT_KEY_IS_FIRST_SESSION = @"+is_first_session";
NSString *const LINKEDME_INIT_KEY_CLICKED_LINKEDME_LINK = @"+clicked_linkedme_link";
NSString *const LINKEDME_PUSH_NOTIFICATION_PAYLOAD_KEY = @"linkedme";

@interface LinkedME () <LMDeepLinkingControllerCompletionDelegate,SKStoreProductViewControllerDelegate>

@property(strong, nonatomic) LMServerInterface *bServerInterface;
@property(strong, nonatomic) NSTimer *sessionTimer;
@property(strong, nonatomic) LMServerRequestQueue *requestQueue;
@property(strong, nonatomic) dispatch_semaphore_t processing_sema;
@property(strong, nonatomic) callbackWithParams sessionInitWithParamsCallback;
@property(strong, nonatomic) callbackWithLinkedMEUniversalObject sessionInitWithLinkedMEUniversalObjectCallback;
@property(assign, nonatomic) NSInteger networkCount;
@property(assign, nonatomic) BOOL isInitialized;
@property(assign, nonatomic) BOOL shouldCallSessionInitCallback;
@property(assign, nonatomic) BOOL shouldAutomaticallyDeepLink;
@property(strong, nonatomic) LMLinkCache *linkCache;
@property(strong, nonatomic) LMPreferenceHelper *preferenceHelper;
@property(strong, nonatomic) LMContentDiscoveryManager *contentDiscoveryManager;
@property(strong, nonatomic) UILongPressGestureRecognizer *debugGestureRecognizer;
@property(strong, nonatomic) NSTimer *debugHeartbeatTimer;
@property(strong, nonatomic) NSString *linkedMeKey;
@property(strong, nonatomic) NSMutableDictionary *deepLinkControllers;
@property(weak  , nonatomic) UIViewController *deepLinkPresentingController;
@property(assign, nonatomic) BOOL useCookieBasedMatching;
@property(strong, nonatomic) NSDictionary *deepLinkDebugParams;
@property(strong, nonatomic) UIControl *view;
@property(strong, nonatomic) NSURL *webpageUrl;

@end

@implementation LinkedME

#pragma mark - Public methods

#pragma mark - GetInstance methods

+ (void)load{
    //Check NAS status of Project info
    id ret = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"NSAppTransportSecurity"];
    if (ret) {
        if ([ret isKindOfClass:[NSDictionary class]]) {
            //if user set NSAllowsArbitraryLoads is true,default is http
            if ([ret[@"NSAllowsArbitraryLoads"]boolValue] == YES && !ret[@"NSAllowsArbitraryLoadsInWebContent"]) {
                [LMPreferenceHelper preferenceHelper].useHTTPS = NO;
            }else{
                [LMPreferenceHelper preferenceHelper].useHTTPS =YES;
            }
        }
        //can't find NSAppTransportSecurity Value
    }else{
        [LMPreferenceHelper preferenceHelper].useHTTPS =YES;
    }
}

+ (LinkedME *)getInstance {
  LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    
    //set LinkedMe_key
    NSString *linkedKey = [preferenceHelper getLinkedMEKey:YES];

  NSString *keyToUse = linkedKey;
  if (!linkedKey) {
    // 如果没有设置appKey
    NSString *appKey = preferenceHelper.appKey;
    if (!appKey) {
      NSLog(@"[LKME Warning] 请在Plist文件中设置LKME_key!");
      return nil;
    } else {
      keyToUse = appKey;
      NSLog(@"Usage of App Key is deprecated, please move toward using a "
            @"LKME key");
    }
  }
  return [LinkedME getInstanceInternal:keyToUse returnNilIfNoCurrentInstance:NO];
}

+ (BOOL)isDebugg{
    return [[self alloc] isDebug];
}

- (BOOL)isDebugg{
    return self.preferenceHelper.isDebug;
}

+(UIViewController *)getViewController {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *vc = keyWindow.rootViewController;
        
        if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = [(UINavigationController *)vc visibleViewController].navigationController;
        } else if ([vc isKindOfClass:[UITabBarController class]]) {
            vc = [(UITabBarController *)vc selectedViewController];
        }

    return vc;
}

#pragma -mark 页面跳转方式

+ (void)presentViewController:(NSString *)vc animated: (BOOL)flag customValue:(NSDictionary *)dict completion:(void (^)(void))completion NS_AVAILABLE_IOS(5_0){
    [self presentViewController:vc storyBoardID:nil animated:flag push:NO customValue:dict completion:completion];
}

+ (void)presentViewController:(NSString *)vc storyBoardID:(NSString *)identifier animated: (BOOL)flag customValue:(NSDictionary *)dict completion:(void (^)(void))completion NS_AVAILABLE_IOS(5_0){
    [self presentViewController:vc storyBoardID:identifier animated:flag push:NO customValue:dict completion:completion];
}

+ (void)pushViewController:(NSString *)vc animated: (BOOL)flag customValue:(NSDictionary *)dict completion:(void (^)(void))completion NS_AVAILABLE_IOS(5_0){
    [self presentViewController:vc storyBoardID:nil animated:flag push:YES customValue:dict completion:completion];
}

+ (void)pushViewController:(NSString *)vc storyBoardID:(NSString *)identifier animated: (BOOL)flag customValue:(NSDictionary *)dict completion:(void (^)(void))completion NS_AVAILABLE_IOS(5_0){
    [self presentViewController:vc storyBoardID:identifier animated:flag push:YES customValue:dict completion:completion];
}

+ (void)presentViewController:(NSString *)vc storyBoardID:(NSString *)identifier animated: (BOOL)flag push:(BOOL)bl customValue:(NSDictionary *)dict completion:(void (^)(void))completion NS_AVAILABLE_IOS(5_0){
    
    UIStoryboard * storyBoard=[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    Class someClass = NSClassFromString(vc);
    
    //判断是纯代码还是storyBoard
    id objj = nil;
    if(identifier){
        objj = [storyBoard instantiateViewControllerWithIdentifier:identifier];
    }else{
        objj = [[someClass alloc] init];
    }
    
    /*
        - (void)configureControlWithData:(NSDictionary *)data {
        _dataDic = data;
     }
     */
    //判断用户是否实现了传参方法
    if([objj respondsToSelector:@selector(configureControlWithData:)]){
        [objj performSelector:NSSelectorFromString(@"configureControlWithData:") withObject:dict];
    }
    
    //页面跳转方式
    if(bl){
        UINavigationController * navi = [LinkedME getViewController];
        [navi pushViewController:objj animated:flag];
    }else{
        [[LinkedME getViewController] presentViewController:objj animated:flag completion:completion];
    }
}

+ (LinkedME *)getInstance:(NSString *)linkedMeKey {
  LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
#warning key需要改变  校验过程
  if ([linkedMeKey rangeOfString:@"key_"].location != NSNotFound) {
    preferenceHelper.linedMEKey = linkedMeKey;
  } else {
    preferenceHelper.appKey = linkedMeKey;
  }
  return [LinkedME getInstanceInternal:linkedMeKey returnNilIfNoCurrentInstance:NO];
}

- (id)initWithInterface:(LMServerInterface *)interface queue:(LMServerRequestQueue *)queue cache:(LMLinkCache *)cache preferenceHelper:(LMPreferenceHelper *)preferenceHelper key:(NSString *)key {
  if (self = [super init]) {
    _bServerInterface = interface;
    _bServerInterface.preferenceHelper = preferenceHelper;
    _requestQueue = queue;
    _linkCache = cache;
    _preferenceHelper = preferenceHelper;
    _linkedMeKey = key;
    _contentDiscoveryManager = [[LMContentDiscoveryManager alloc] init];
    _isInitialized = NO;
    _shouldCallSessionInitCallback = YES;
    _processing_sema = dispatch_semaphore_create(1);
    _networkCount = 0;
    _deepLinkControllers = [[NSMutableDictionary alloc] init];
    _useCookieBasedMatching = YES;

    NSNotificationCenter *notificationCenter =
        [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
      
      
    [notificationCenter addObserver:self
                             selector:@selector(applicationDidEnterBackground)
                                 name:UIApplicationDidEnterBackgroundNotification
                               object:nil];
  }

  return self;
}


- (void)applicationDidEnterBackground{
    if (_view.userInteractionEnabled) {
        _view.userInteractionEnabled = NO;
    }
    return;
}

#pragma mark - 配置方法

//设置Debug模式-实例方法
- (void)setDebug {
    self.preferenceHelper.isDebug = YES;
}

- (void)getSafariCookice:(BOOL)status{
    self.preferenceHelper.getSafariCookice = status;
}

+ (NSString *)getTestID{
    return [LMSystemObserver getTestID];
}

- (void)disableMatching{
//    self.preferenceHelper.closeEnable = NO;
    self.preferenceHelper.disableLocation = YES;
}

//重置用户会话
- (void)resetUserSession {
  self.isInitialized = NO;
}

//用户识别
- (BOOL)isUserIdentified {
  return self.preferenceHelper.userIdentity != nil;
}

//设置网络超时时间
- (void)setNetworkTimeout:(NSTimeInterval)timeout {
  self.preferenceHelper.timeout = timeout;
}

//设置最大重置次数
- (void)setMaxRetries:(NSInteger)maxRetries {
  self.preferenceHelper.retryCount = maxRetries;
}

//设置重试次数间隔
- (void)setRetryInterval:(NSTimeInterval)retryInterval {
  self.preferenceHelper.retryInterval = retryInterval;
}

//禁用基于cookie匹配
- (void)disableCookieBasedMatching {
  self.useCookieBasedMatching = NO;
}

//新增
- (void)enableDelayedInit {
    self.preferenceHelper.shouldWaitForInit = YES;
    self.useCookieBasedMatching = NO; // Developers delaying init should implement their own SFSafariViewController
}

- (void)disableDelayedInit {
    self.preferenceHelper.shouldWaitForInit = NO;
}

- (void)resumeInit {
    self.preferenceHelper.shouldWaitForInit = NO;
    if (self.isInitialized) {
        NSLog(@"[LinkedME Error] User session has already been initialized, so resumeInit is aborting.");
    }
    else if (![self.requestQueue containsInstallOrOpen]) {
        NSLog(@"[LinkedME Error] No install or open request, so resumeInit is aborting.");
    }
    else {
        [self processNextQueueItem];
    }
}

#pragma mark - InitSession Permutation methods

- (void)initSessionWithLaunchOptions:(NSDictionary *)options {
  [self initSessionWithLaunchOptions:options
                        isReferrable:YES
       explicitlyRequestedReferrable:NO
      automaticallyDisplayController:NO
             registerDeepLinkHandler:nil];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options
          andRegisterDeepLinkHandler:(callbackWithParams)callback {
  [self initSessionWithLaunchOptions:options
                        isReferrable:YES
       explicitlyRequestedReferrable:NO
      automaticallyDisplayController:NO
             registerDeepLinkHandler:callback];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options
    andRegisterDeepLinkHandlerUsingLinkedMEUniversalObject:
        (callbackWithLinkedMEUniversalObject)callback {
  [self initSessionWithLaunchOptions:options
                                           isReferrable:YES
                          explicitlyRequestedReferrable:NO
                         automaticallyDisplayController:NO
      registerDeepLinkHandlerUsingLinkedMEUniversalObject:callback];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options
                        isReferrable:(BOOL)isReferrable {
  [self initSessionWithLaunchOptions:options
                        isReferrable:isReferrable
       explicitlyRequestedReferrable:YES
      automaticallyDisplayController:NO
             registerDeepLinkHandler:nil];
}

-
    (void)initSessionWithLaunchOptions:(NSDictionary *)options
automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController {
  [self initSessionWithLaunchOptions:options
                        isReferrable:YES
       explicitlyRequestedReferrable:NO
      automaticallyDisplayController:automaticallyDisplayController
             registerDeepLinkHandler:nil];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options
                        isReferrable:(BOOL)isReferrable
          andRegisterDeepLinkHandler:(callbackWithParams)callback {
  [self initSessionWithLaunchOptions:options
                        isReferrable:isReferrable
       explicitlyRequestedReferrable:YES
      automaticallyDisplayController:NO
             registerDeepLinkHandler:callback];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options
    automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController
                           deepLinkHandler:(callbackWithParams)callback {
    
    
    
  [self initSessionWithLaunchOptions:options
                        isReferrable:YES
       explicitlyRequestedReferrable:NO
      automaticallyDisplayController:automaticallyDisplayController
             registerDeepLinkHandler:callback];
}

-(void)initSessionWithLaunchOptions:(NSDictionary *)options
                          isReferrable:(BOOL)isReferrable
      automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController {
      [self initSessionWithLaunchOptions:options
                        isReferrable:isReferrable
       explicitlyRequestedReferrable:YES
      automaticallyDisplayController:automaticallyDisplayController
             registerDeepLinkHandler:nil];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options
    automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController
                              isReferrable:(BOOL)isReferrable
                           deepLinkHandler:(callbackWithParams)callback {
  [self initSessionWithLaunchOptions:options
                        isReferrable:isReferrable
       explicitlyRequestedReferrable:YES
      automaticallyDisplayController:automaticallyDisplayController
             registerDeepLinkHandler:callback];
}

#pragma mark - Actual Init Session

- (void)initSessionWithLaunchOptions:(NSDictionary *)options
                                         isReferrable:(BOOL)isReferrable
                        explicitlyRequestedReferrable:
                            (BOOL)explicitlyRequestedReferrable
                       automaticallyDisplayController:
                           (BOOL)automaticallyDisplayController
    registerDeepLinkHandlerUsingLinkedMEUniversalObject:
        (callbackWithLinkedMEUniversalObject)callback {
  self.sessionInitWithLinkedMEUniversalObjectCallback = callback;
  [self initSessionWithLaunchOptions:options
                        isReferrable:isReferrable
       explicitlyRequestedReferrable:explicitlyRequestedReferrable
      automaticallyDisplayController:automaticallyDisplayController];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options
                        isReferrable:(BOOL)isReferrable
       explicitlyRequestedReferrable:(BOOL)explicitlyRequestedReferrable
      automaticallyDisplayController:(BOOL)automaticallyDisplayController
             registerDeepLinkHandler:(callbackWithParams)callback {
  self.sessionInitWithParamsCallback = callback;
  [self initSessionWithLaunchOptions:options
                        isReferrable:isReferrable
       explicitlyRequestedReferrable:explicitlyRequestedReferrable
      automaticallyDisplayController:automaticallyDisplayController];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options
                        isReferrable:(BOOL)isReferrable
       explicitlyRequestedReferrable:(BOOL)explicitlyRequestedReferrable
      automaticallyDisplayController:(BOOL)automaticallyDisplayController {
    
  self.shouldAutomaticallyDeepLink = automaticallyDisplayController;

  self.preferenceHelper.explicitlyRequestedReferrable =
      explicitlyRequestedReferrable;
    
    
  // Handle push notification on app launch
  if ([options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
    id linkedMeUrlFromPush =
        [options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]
            [LINKEDME_PUSH_NOTIFICATION_PAYLOAD_KEY];
    if ([linkedMeUrlFromPush isKindOfClass:[NSString class]]) {
      self.preferenceHelper.universalLinkUrl = linkedMeUrlFromPush;
    }
  }

  if ([LMSystemObserver getOSVersion].integerValue >= 8) {
    
    if (![options objectForKey:UIApplicationLaunchOptionsURLKey] && ![options objectForKey:UIApplicationLaunchOptionsUserActivityDictionaryKey]) {
      [self initUserSessionAndCallCallback:YES];
    }
      
    else if ([options.allKeys containsObject:UIApplicationLaunchOptionsUserActivityDictionaryKey]) {
        // Wait for continueUserActivity AppDelegate call to come through
        self.preferenceHelper.shouldWaitForInit = YES;
    }
    
    else if ([options objectForKey:UIApplicationLaunchOptionsUserActivityDictionaryKey]) {
      self.preferenceHelper.isContinuingUserActivity = YES;
    }
  }
  
  else if (![options objectForKey:UIApplicationLaunchOptionsURLKey]) {
    [self initUserSessionAndCallCallback:YES];
  }
    
//    shouldWaitForInit
}

// these params will be added
- (void)setDeepLinkDebugMode:(NSDictionary *)debugParams {
  self.deepLinkDebugParams = debugParams;
}

/**
 *  处理DeepLink
 *
 *  @param url 外部url
 *
 *  @return 状态
 */
- (BOOL)handleDeepLink:(NSURL *)url {
  BOOL handled = NO;
  if (url) {
    //在preferenceHelper存储url
    self.preferenceHelper.externalIntentURI = [url absoluteString];

    NSString *query = [url fragment];
    if (!query) {
      query = [url query];
    }

    NSDictionary *params = [LMEncodingUtils decodeQueryStringToDictionary:query];
    if (params[@"click_id"]) {
      handled = YES;
      self.preferenceHelper.linkClickIdentifier = params[@"click_id"];
    }//网络链接不正常时直接在scheme中获取参数返回
      else if ([[url description] rangeOfString:@"lkme=1"].location != NSNotFound) {
        NSMutableDictionary *data = [[NSMutableDictionary alloc]init];
        [data setObject:params forKey:@"$control"];
        self.sessionInitWithParamsCallback(data,nil);
      }
  }

  [self initUserSessionAndCallCallback:YES];

  return handled;
}


- (UIWindow *)statusWindow{
    NSString *statusBarString = [NSString stringWithFormat:@"_%@%@%@",@"status",@"Bar",@"Window"];
    return [[UIApplication sharedApplication] valueForKey:statusBarString];
}

- (void)openLinkedMEUrl{
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];

    NSURL *url = [[NSURL alloc]init];

    _view.userInteractionEnabled = NO;
    if (preferenceHelper.callBackUrl) {
        url = [NSURL URLWithString:preferenceHelper.callBackUrl];
    }else{
        url = _webpageUrl;
    }
    
    [[UIApplication sharedApplication] openURL:url];
}


-(void)handleAppDidBackGround{
    if (_view.userInteractionEnabled) {
        _view.userInteractionEnabled = NO;
    }
    return;
}

//- (UIViewController *)currentViewController{
//    UIWindow *keyWindow  = [UIApplication sharedApplication].keyWindow;
//    UIViewController *vc = keyWindow.rootViewController;
//    while (vc.presentedViewController)
//    {
//        vc = vc.presentedViewController;
//        
//        if ([vc isKindOfClass:[UINavigationController class]])
//        {
//            vc = [(UINavigationController *)vc visibleViewController];
//        }
//        else if ([vc isKindOfClass:[UITabBarController class]])
//        {
//            vc = [(UITabBarController *)vc selectedViewController];
//        }
//    }
//    return vc;
//}
//
//- (UINavigationController *)currentNavigationController{
//    return [self currentViewController].navigationController;
//}

- (BOOL)continueUserActivity:(NSUserActivity *)userActivity  API_AVAILABLE(ios(8.0)){
    
    __weak typeof(self) weakSelf = self;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 10.0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //创建右上角遮罩
            weakSelf.view = [[UIControl alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-80, 0, 80, 19)];
            weakSelf.view.userInteractionEnabled = YES;
            weakSelf.view.backgroundColor = [UIColor clearColor];
            [weakSelf.view addTarget:self action:@selector(openLinkedMEUrl) forControlEvents:UIControlEventTouchUpInside];
            [[self statusWindow] addSubview:weakSelf.view];
        });
    }
    
    //检查是否需要处理浏览器请求
  if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
    self.preferenceHelper.universalLinkUrl = [userActivity.webpageURL absoluteString];
    self.preferenceHelper.shouldWaitForInit = NO;
      
    [self initUserSessionAndCallCallback:YES];
    self.preferenceHelper.isContinuingUserActivity = NO;
   
    id linkedMEUniversalLinkDomains = [self.preferenceHelper getLinkedMEUniversalLinkDomains];
     
      _webpageUrl = userActivity.webpageURL;
    if ([linkedMEUniversalLinkDomains isKindOfClass:[NSString class]] &&
        [[userActivity.webpageURL absoluteString]
            containsString:linkedMEUniversalLinkDomains]) {
      return YES;
            
    } else if ([linkedMEUniversalLinkDomains isKindOfClass:[NSArray class]]) {
      for (id oneDomain in linkedMEUniversalLinkDomains) {
        if ([oneDomain isKindOfClass:[NSString class]] &&
            [[userActivity.webpageURL absoluteString]
                containsString:oneDomain]) {
          return YES;
        }
      }
    }
      NSLog(@"****%@",[userActivity.webpageURL absoluteString]);
      return [userActivity.webpageURL absoluteString];
//      return @"www.lkme.cc";
  }

  //检查是否需要处理spotlight数据
  NSString *spotlightIdentifier = [self.contentDiscoveryManager
      spotlightIdentifierFromActivity:userActivity];

  if (spotlightIdentifier) {
//    self.preferenceHelper.spotlightIdentifier = spotlightIdentifier;
      //spltlightIdentifier
      self.preferenceHelper.spotlightIdentifier = [userActivity.webpageURL absoluteString];
  } else {
    NSString *nonLinkedMESpotlightIdentifier = [self.contentDiscoveryManager
        standardSpotlightIdentifierFromActivity:userActivity];
    if (nonLinkedMESpotlightIdentifier) {
      self.preferenceHelper.spotlightIdentifier = nonLinkedMESpotlightIdentifier;
    }
  }

    self.preferenceHelper.shouldWaitForInit = NO;

  [self initUserSessionAndCallCallback:YES];
  self.preferenceHelper.isContinuingUserActivity = NO;

  return spotlightIdentifier != nil;
}

#pragma mark - Generic Request support

- (void)executeGenericRequest:(LMServerRequest *)request {
  [self initSessionIfNeededAndNotInProgress];
  [self.requestQueue enqueue:request];
  [self processNextQueueItem];
}

#pragma mark - Push Notification support

// 如果app已经启动处理推送通知
- (void)handlePushNotification:(NSDictionary *)userInfo {
  // 如果当前App是活跃的先关闭当前会话，再启一个新的会话
  if ([[UIApplication sharedApplication] applicationState] ==
      UIApplicationStateActive) {
    [self calledClose];
  }

  // look for a LKME shortlink in the payload (shortlink because iOS7 only
  // supports 256 bytes)
  NSString *urlStr = [userInfo objectForKey:LINKEDME_PUSH_NOTIFICATION_PAYLOAD_KEY];
  if (urlStr) {
    // reusing this field, so as not to create yet another url slot on
    // prefshelper
    self.preferenceHelper.universalLinkUrl = urlStr;
  }

    // 再次判断如果当前App是活跃的先关闭当前会话，再启一个新的会话
  if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
    [self applicationDidBecomeActive];
  }
}

#pragma mark - Deep Link Controller methods

- (void)registerDeepLinkController:
            (UIViewController<LMDeepLinkingController> *)controller
                            forKey:(NSString *)key {
  self.deepLinkControllers[key] = controller;
}

#pragma mark - Identity methods

- (void)setIdentity:(NSString *)userId {
  [self setIdentity:userId withCallback:NULL];
}

- (void)setIdentity:(NSString *)userId
       withCallback:(callbackWithParams)callback {
  if (!userId || [self.preferenceHelper.userIdentity isEqualToString:userId]) {
    if (callback) {
      callback([self getFirstReferringParams], nil);
    }
    return;
  }

  [self initSessionIfNeededAndNotInProgress];

  LMSetIdentityRequest *req =
      [[LMSetIdentityRequest alloc] initWithUserId:userId
                                              callback:callback];
  [self.requestQueue enqueue:req];
  [self processNextQueueItem];
}

- (void)logout {
  [self logoutWithCallback:nil];
}

- (void)logoutWithCallback:(callbackWithStatus)callback {
  if (!self.isInitialized) {
    NSLog(@"LinkedME没有初始化不能注销");
    if (callback) {
      callback(NO, nil);
    }
  }

  LMLoadRewardsRequest *req = [[LMLoadRewardsRequest alloc]
      initWithCallback:^(BOOL success, NSError *error) {
        if (success) {
          // 清除缓存连接
          self.linkCache = [[LMLinkCache alloc] init];

          if (callback) {
            callback(YES, nil);
          }
          if (self.preferenceHelper.isDebug) {
            NSLog(@"注销成功");
          }
        } else /*失败*/ {
          if (callback) {
            callback(NO, error);
          }
          if (self.preferenceHelper.isDebug) {
            NSLog(@"注销失败");
          }
        }
      }];

  [self.requestQueue enqueue:req];
  [self processNextQueueItem];
}


#pragma mark - Credit methods


- (LMUniversalObject *)getFirstReferringLinkedMEUniversalObject {
  NSDictionary *params = [self getFirstReferringParams];
  if ([[params objectForKey:LINKEDME_INIT_KEY_CLICKED_LINKEDME_LINK] isEqual:@1]) {
    return
        [LMUniversalObject getLinkedMEUniversalObjectFromDictionary:params];
  }
  return nil;
}

- (LMLinkProperties *)getFirstReferringLinkedMELinkProperties {
  NSDictionary *params = [self getFirstReferringParams];
  if ([[params objectForKey:LINKEDME_INIT_KEY_CLICKED_LINKEDME_LINK] isEqual:@1]) {
    return [LMLinkProperties getLinkedMELinkPropertiesFromDictionary:params];
  }
  return nil;
}


// 1.0改版 json改成kv方式
- (NSDictionary *)getFirstReferringParams {
  NSDictionary *origInstallParams = [LMEncodingUtils
      decodeJsonStringToDictionary:self.preferenceHelper.installParams];
    
  return origInstallParams;
}

- (NSDictionary *)getLatestReferringParams {
  NSDictionary *origSessionParams = [LMEncodingUtils
      decodeJsonStringToDictionary:self.preferenceHelper.sessionParams];
    
  return origSessionParams;
}

- (LMUniversalObject *)getLatestReferringLinkedMEUniversalObject {
  NSDictionary *params = [self getLatestReferringParams];
  if ([[params objectForKey:LINKEDME_INIT_KEY_CLICKED_LINKEDME_LINK] isEqual:@1]) {
    return
        [LMUniversalObject getLinkedMEUniversalObjectFromDictionary:params];
  }
  return nil;
}

- (LMLinkProperties *)getLatestReferringLinkedMELinkProperties {
  NSDictionary *params = [self getLatestReferringParams];
  if ([[params objectForKey:LINKEDME_INIT_KEY_CLICKED_LINKEDME_LINK] isEqual:@1]) {
    return [LMLinkProperties getLinkedMELinkPropertiesFromDictionary:params];
  }
  return nil;
}


#warning 保留
- (void)getShortUrlWithParams:(NSDictionary *)params
                      andTags:(NSArray *)tags
                     andAlias:(NSString *)alias
             andMatchDuration:(NSUInteger)duration
                   andChannel:(NSString *)channel
                   andFeature:(NSString *)feature
                     andStage:(NSString *)stage
                  andCallback:(callbackWithUrl)callback {
  [self generateShortUrl:tags
                andAlias:alias
                 andType:LinkedMELinkTypeUnlimitedUse
        andMatchDuration:duration
              andChannel:channel
              andFeature:feature
                andStage:stage
               andParams:params
             andCallback:callback];
}

- (void)getSpotlightUrlWithParams:(NSDictionary *)params
                         callback:(callbackWithParams)callback {
  [self initSessionIfNeededAndNotInProgress];

  LMSpotlightUrlRequest *req =
      [[LMSpotlightUrlRequest alloc] initWithParams:params
                                               callback:callback];
  [self.requestQueue enqueue:req];
  [self processNextQueueItem];
}


#pragma mark - Discoverable content methods


- (void)createDiscoverableContentWithTitle:(NSString *)title
                               description:(NSString *)description
                              thumbnailUrl:(NSURL *)thumbnailUrl
                                linkParams:(NSDictionary *)linkParams
                                      type:(NSString *)type
                         publiclyIndexable:(BOOL)publiclyIndexable
                                  keywords:(NSSet *)keywords
                            expirationDate:(NSDate *)expirationDate
                       spotlightIdentifier:(NSString *)identifier
                                  callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title
                                            description:description
                                      publiclyIndexable:publiclyIndexable
                                                   type:type
                                           thumbnailUrl:thumbnailUrl
                                               keywords:keywords
                                               userInfo:linkParams
                                         expirationDate:expirationDate
                                    spotlightIdentifier:identifier
                                               callback:callback
                                      spotlightCallback:nil];
}

// 仅支持iOS 9及以上
- (void)createDiscoverableContentWithTitle:(NSString *)title
                               description:(NSString *)description
                              thumbnailUrl:(NSURL *)thumbnailUrl
                                linkParams:(NSDictionary *)linkParams
                                      type:(NSString *)type
                         publiclyIndexable:(BOOL)publiclyIndexable
                                  keywords:(NSSet *)keywords
                            expirationDate:(NSDate *)expirationDate
                       spotlightIdentifier:(NSString *)identifier
                         spotlightCallback:
                             (callbackWithUrlAndSpotlightIdentifier)
                                 spotlightCallback {
    [self.contentDiscoveryManager indexContentWithTitle:title
                                            description:description
                                      publiclyIndexable:publiclyIndexable
                                                   type:type
                                           thumbnailUrl:thumbnailUrl
                                               keywords:keywords
                                               userInfo:linkParams
                                         expirationDate:expirationDate
                                    spotlightIdentifier:identifier
                                               callback:nil
                                      spotlightCallback:spotlightCallback];
    
//    [self.contentDiscoveryManager indexContentWithTitle:title
//                                            description:description
//                                      publiclyIndexable:publiclyIndexable
//                                                   type:type
//                                           thumbnailUrl:thumbnailUrl
//                                               keywords:keywords
//                                               userInfo:nil
//                                         expirationDate:expirationDate
//                                    spotlightIdentifier:identifier
//                                               callback:nil
//                                      spotlightCallback:spotlightCallback];
}

#pragma mark - Spotlight删除方法
+ (void)removeSearchItemWith:(NSArray *)dataArray{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        [[CSSearchableIndex defaultSearchableIndex]deleteSearchableItemsWithIdentifiers:dataArray completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
}

+ (void)removeAllSearchItems{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        [[CSSearchableIndex defaultSearchableIndex] deleteAllSearchableItemsWithCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Spotlight删除错误%@", error.localizedFailureReason);
            }
        }];
    }
}



#pragma mark - Referral methods

//- (NSString *)getReferralUrlWithParams:(NSDictionary *)params
//                               andTags:(NSArray *)tags
//                            andChannel:(NSString *)channel {
//  return [self generateShortUrl:tags
//                       andAlias:nil
//                        andType:LinkedMELinkTypeUnlimitedUse
//               andMatchDuration:0
//                     andChannel:channel
//                     andFeature:LINKEDME_FEATURE_TAG_REFERRAL
//                       andStage:nil
//                      andParams:params
//                 ignoreUAString:nil
//              forceLinkCreation:NO];
//}
//
//- (NSString *)getReferralUrlWithParams:(NSDictionary *)params
//                            andChannel:(NSString *)channel {
//  return [self generateShortUrl:nil
//                       andAlias:nil
//                        andType:LinkedMELinkTypeUnlimitedUse
//               andMatchDuration:0
//                     andChannel:channel
//                     andFeature:LINKEDME_FEATURE_TAG_REFERRAL
//                       andStage:nil
//                      andParams:params
//                 ignoreUAString:nil
//              forceLinkCreation:NO];
//}
//
//- (void)getReferralUrlWithParams:(NSDictionary *)params
//                         andTags:(NSArray *)tags
//                      andChannel:(NSString *)channel
//                     andCallback:(callbackWithUrl)callback {
//  [self generateShortUrl:tags
//                andAlias:nil
//                 andType:LinkedMELinkTypeUnlimitedUse
//        andMatchDuration:0
//              andChannel:channel
//              andFeature:LINKEDME_FEATURE_TAG_REFERRAL
//                andStage:nil
//               andParams:params
//             andCallback:callback];
//}
//
//- (void)getReferralUrlWithParams:(NSDictionary *)params
//                      andChannel:(NSString *)channel
//                     andCallback:(callbackWithUrl)callback {
//  [self generateShortUrl:nil
//                andAlias:nil
//                 andType:LinkedMELinkTypeUnlimitedUse
//        andMatchDuration:0
//              andChannel:channel
//              andFeature:LINKEDME_FEATURE_TAG_REFERRAL
//                andStage:nil
//               andParams:params
//             andCallback:callback];
//}


#pragma mark - 私有方法

+ (LinkedME *)getInstanceInternal:(NSString *)key
   returnNilIfNoCurrentInstance:(BOOL)returnNilIfNoCurrentInstance {
  static LinkedME *linkedMe;

  if (!linkedMe && returnNilIfNoCurrentInstance) {
    return nil;
  }

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    LMPreferenceHelper *preferenceHelper =
        [LMPreferenceHelper preferenceHelper];

    // If there was stored key and it isn't the same as the currently used (or
    // doesn't exist), we need to clean up
    // Note: Link Click Identifier is not cleared because of the potential for
    // that to mess up a deep link
    if (preferenceHelper.lastRunLinkedMeKey &&
        ![key isEqualToString:preferenceHelper.lastRunLinkedMeKey]) {
      NSLog(@"[LKME Warning] The LKME Key has changed, clearing relevant "
            @"items");

      preferenceHelper.appVersion = nil;
      preferenceHelper.deviceFingerprintID = nil;
      preferenceHelper.sessionID = nil;
      preferenceHelper.identityID = nil;
      preferenceHelper.userUrl = nil;
      preferenceHelper.installParams = nil;
      preferenceHelper.sessionParams = nil;

      [[LMServerRequestQueue getInstance] clearQueue];
    }

    preferenceHelper.lastRunLinkedMeKey = key;

    linkedMe =
        [[LinkedME alloc] initWithInterface:[[LMServerInterface alloc] init]
                                    queue:[LMServerRequestQueue getInstance]
                                    cache:[[LMLinkCache alloc] init]
                         preferenceHelper:preferenceHelper
                                      key:key];
  });

  return linkedMe;
}

#pragma mark - 生成短链方法

- (void)generateShortUrl:(NSArray *)tags
                andAlias:(NSString *)alias
                 andType:(LMLinkType)type
        andMatchDuration:(NSUInteger)duration
              andChannel:(NSString *)channel
              andFeature:(NSString *)feature
                andStage:(NSString *)stage
               andParams:(NSDictionary *)params
             andCallback:(callbackWithUrl)callback {
    
            [self initSessionIfNeededAndNotInProgress];
    
           LMLinkData *linkData = [self prepareLinkDataFor:tags
                                          andAlias:alias
                                           andType:type
                                  andMatchDuration:duration
                                        andChannel:channel
                                        andFeature:feature
                                          andStage:stage
                                         andParams:params
                                    ignoreUAString:nil];

  if ([self.linkCache objectForKey:linkData]) {
    if (callback) {
      callback([self.linkCache objectForKey:linkData], nil);
    }
    return;
  }

  LMShortUrlRequest *req =
      [[LMShortUrlRequest alloc] initWithTags:tags
                                            alias:alias
                                             type:type
                                    matchDuration:duration
                                          channel:channel
                                          feature:feature
                                            stage:stage
                                           params:params
                                         linkData:linkData
                                        linkCache:self.linkCache
                                         callback:callback];
  [self.requestQueue enqueue:req];
  [self processNextQueueItem];
}

- (NSString *)generateShortUrl:(NSArray *)tags
                      andAlias:(NSString *)alias
                       andType:(LMLinkType)type
              andMatchDuration:(NSUInteger)duration
                    andChannel:(NSString *)channel
                    andFeature:(NSString *)feature
                      andStage:(NSString *)stage
                     andParams:(NSDictionary *)params
                ignoreUAString:(NSString *)ignoreUAString
             forceLinkCreation:(BOOL)forceLinkCreation {
  NSString *shortURL = nil;

  LMLinkData *linkData = [self prepareLinkDataFor:tags
                                          andAlias:alias
                                           andType:type
                                  andMatchDuration:duration
                                        andChannel:channel
                                        andFeature:feature
                                          andStage:stage
                                         andParams:params
                                    ignoreUAString:ignoreUAString];

  // If an ignore UA string is present, we always get a new url. Otherwise, if
  // we've already seen this request, use the cached version
  if (!ignoreUAString && [self.linkCache objectForKey:linkData]) {
    shortURL = [self.linkCache objectForKey:linkData];
  }
  return shortURL;
}

- (NSString *)generateLongURLWithParams:(NSDictionary *)params
                             andChannel:(NSString *)channel
                                andTags:(NSArray *)tags
                             andFeature:(NSString *)feature
                               andStage:(NSString *)stage
                               andAlias:(NSString *)alias {
  NSString *baseLongUrl =
      [NSString stringWithFormat:@"%@/a/%@", LKME_LINK_URL, self.linkedMeKey];

  return [self longUrlWithBaseUrl:baseLongUrl
                           params:params
                             tags:tags
                          feature:feature
                          channel:nil
                            stage:stage
                            alias:alias
                         duration:0
                             type:LinkedMELinkTypeUnlimitedUse];
}

- (NSString *)longUrlWithBaseUrl:(NSString *)baseUrl
                          params:(NSDictionary *)params
                            tags:(NSArray *)tags
                         feature:(NSString *)feature
                         channel:(NSString *)channel
                           stage:(NSString *)stage
                           alias:(NSString *)alias
                        duration:(NSUInteger)duration
                            type:(LMLinkType)type {
  NSMutableString *longUrl =
      [[NSMutableString alloc] initWithFormat:@"%@?", baseUrl];

  for (NSString *tag in tags) {
    [longUrl appendFormat:@"tags=%@&", tag];
  }

  if ([alias length]) {
    [longUrl appendFormat:@"alias=%@&", alias];
  }

  if ([channel length]) {
    [longUrl appendFormat:@"channel=%@&", channel];
  }

  if ([feature length]) {
    [longUrl appendFormat:@"feature=%@&", feature];
  }

  if ([stage length]) {
    [longUrl appendFormat:@"stage=%@&", stage];
  }

  [longUrl appendFormat:@"type=%ld&", (long)type];
  [longUrl appendFormat:@"matchDuration=%ld&", (long)duration];

  NSData *jsonData = [LMEncodingUtils encodeDictionaryToJsonData:params];
  NSString *base64EncodedParams = [LMEncodingUtils base64EncodeData:jsonData];
  [longUrl appendFormat:@"source=iOS&data=%@", base64EncodedParams];

  return longUrl;
}

- (LMLinkData *)prepareLinkDataFor:(NSArray *)tags
                           andAlias:(NSString *)alias
                            andType:(LMLinkType)type
                   andMatchDuration:(NSUInteger)duration
                         andChannel:(NSString *)channel
                         andFeature:(NSString *)feature
                           andStage:(NSString *)stage
                          andParams:(NSDictionary *)params
                     ignoreUAString:(NSString *)ignoreUAString {
  LMLinkData *post = [[LMLinkData alloc] init];

  [post setupType:type];
  [post setupTags:tags];
  [post setupChannel:channel];
  [post setupFeature:feature];
  [post setupStage:stage];
  [post setupAlias:alias];
  [post setupMatchDuration:duration];
  [post setupIgnoreUAString:ignoreUAString];
  [post setupParams:params];

  return post;
}

#pragma mark - LinkedMEUniversalObject methods

- (void)registerViewWithParams:(NSDictionary *)params
                   andCallback:(callbackWithParams)callback {
  [self initSessionIfNeededAndNotInProgress];

  LMRegisterViewRequest *req =
      [[LMRegisterViewRequest alloc] initWithParams:params
                                            andCallback:callback];
  [self.requestQueue enqueue:req];
  [self processNextQueueItem];
}

#pragma mark - Application State Change methods

//- (void)applicationDidBecomeActive {
//  if (!self.isInitialized && !self.preferenceHelper.isContinuingUserActivity &&
//      ![self.requestQueue containsInstallOrOpen]) {
//    [self initUserSessionAndCallCallback:YES];
//  }
//}

- (void)applicationDidBecomeActive {
    [self clearTimer];
    if (!self.isInitialized && !self.preferenceHelper.shouldWaitForInit && ![self.requestQueue containsInstallOrOpen]) {
        [self initUserSessionAndCallCallback:YES];
    }
}

//- (void)applicationWillResignActive {
//  [self clearTimer];
//  self.sessionTimer =
//      [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(calledClose) userInfo:nil repeats:NO];
//  [self.requestQueue persistImmediately];
//
//  if (self.debugGestureRecognizer) {
//    [[UIApplication sharedApplication].keyWindow removeGestureRecognizer:self.debugGestureRecognizer];
//  }
//}

- (void)applicationWillResignActive {
    [self clearTimer];
    self.sessionTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(callClose) userInfo:nil repeats:NO];
    [self.requestQueue persistImmediately];
}

- (void)clearTimer {
  [self.sessionTimer invalidate];
}

- (void)callClose {
    if (self.isInitialized) {
        self.isInitialized = NO;
        
    if (self.preferenceHelper.sessionID && ![self.requestQueue containsClose]) {
        LMCloseRequest *req = [[LMCloseRequest alloc]init];
        [self.requestQueue enqueue:req];
    }
    
        [self processNextQueueItem];
    }
}

- (void)calledClose {
//    _view.userInteractionEa                                                                bled = NO;
  if (self.isInitialized) {
    self.isInitialized = NO;

    if (self.preferenceHelper.sessionID && ![self.requestQueue containsClose]) {
      LMCloseRequest *req = [[LMCloseRequest alloc] init];
      [self.requestQueue enqueue:req];
    }
    [self processNextQueueItem];
  }
}

#pragma mark - Queue management

- (void)insertRequestAtFront:(LMServerRequest *)req {
    
//    if (self.networkCount == 0) {
//        [self.requestQueue insert:req at:0];
//    }
//    else {
//        [self.requestQueue insert:req at:1];
//    }
    
  if (self.networkCount == 0) {
    [self.requestQueue insert:req at:0];
  } else {
// 强制把networkCount设为0,并把队列中的队尾删除(LMCloseRequest)
    [self.requestQueue insert:req at:0];
      self.networkCount = 0;
      [self.requestQueue removeAt:self.requestQueue.size -1];
  }
}

- (void)processNextQueueItem {
    dispatch_semaphore_wait(self.processing_sema, DISPATCH_TIME_FOREVER);
    
    if (self.networkCount == 0 && self.requestQueue.size > 0 && !self.preferenceHelper.shouldWaitForInit) {
        self.networkCount = 1;
        dispatch_semaphore_signal(self.processing_sema);
        
        LMServerRequest *req = [self.requestQueue peek];
        
        if (req) {
            LMServerCallback callback = ^(LMServerResponse *response, NSError *error) {
                // If the request was successful, or was a bad user request, continue processing.
                if (!error || error.code == LKMEBadRequestError || error.code == LKMEDuplicateResourceError) {
                    [req processResponse:response error:error];
                    
                    [self.requestQueue dequeue];
                    self.networkCount = 0;
                    [self processNextQueueItem];
                }
                // On network problems, or LinkedME down, call the other callbacks and stop processing.
                else {
                    // First, gather all the requests to fail
                    NSMutableArray *requestsToFail = [[NSMutableArray alloc] init];
                    for (int i = 0; i < self.requestQueue.size; i++) {
                        LMServerRequest *request = [self.requestQueue peekAt:i];
                        if (request) {
                            [requestsToFail addObject:request];
                        }
                    }
                    
                    // Then, set the network count to zero, indicating that requests can be started again
                    self.networkCount = 0;
                    
                    // Finally, call all the requests callbacks with the error
                    for (LMServerRequest *request in requestsToFail) {
                        [request processResponse:nil error:error];
                    }
                }
            };
            
            if (![req isKindOfClass:[LMInstallRequest class]] && !self.preferenceHelper.identityID) {
                NSLog(@"[LinkedME Error] User session has not been initialized!");
                [req processResponse:nil error:[NSError errorWithDomain:LMErrorDomain code:LKMEInitError userInfo:@{ NSLocalizedDescriptionKey: @"LinkedME User Session has not been initialized" }]];
                return;
            }
            else if (![req isKindOfClass:[LMOpenRequest class]] && (!self.preferenceHelper.deviceFingerprintID || !self.preferenceHelper.sessionID)) {
                NSLog(@"[LinkedME Error] Missing session items!");
                [req processResponse:nil error:[NSError errorWithDomain:LMErrorDomain code:LKMEInitError userInfo:@{ NSLocalizedDescriptionKey: @"LinkedME User Session has not been initialized" }]];
                return;
            }
            
            [req makeRequest:self.bServerInterface key:self.linkedMeKey callback:callback];
        }
    }
    else {
        dispatch_semaphore_signal(self.processing_sema);
    }
}

#pragma mark - Session Initialization

- (void)initSessionIfNeededAndNotInProgress {
  if (!self.isInitialized && !self.preferenceHelper.isContinuingUserActivity &&
      ![self.requestQueue containsInstallOrOpen]) {
    [self initUserSessionAndCallCallback:NO];
  }
}

- (void)initUserSessionAndCallCallback:(BOOL)callCallback {
    
  self.shouldCallSessionInitCallback = callCallback;

  // 如果沒有初始化先進行初始化
  if (!self.isInitialized) {
    [self initializeSession];
  }
  // 如果初始化了且指定了回调
  else if (callCallback) {
      
    if (self.sessionInitWithParamsCallback) {
      self.sessionInitWithParamsCallback([self getLatestReferringParams], nil);
    } else if (self.sessionInitWithLinkedMEUniversalObjectCallback) {
      self.sessionInitWithLinkedMEUniversalObjectCallback(
          [self getLatestReferringLinkedMEUniversalObject],
          [self getLatestReferringLinkedMELinkProperties], nil);
    }
  }
}


- (void)initializeSession {
  if (!self.linkedMeKey) {
    NSLog(@"[LinkedME Warning] 请在plist.info中设置linkedme_key!");
    return;
  } else if ([self.linkedMeKey rangeOfString:@"key_test_"].location !=
             NSNotFound) {
  }
    
    /**
     *  Description 判断当前app状态,新增用户和更新用户调用LMInstallRequest,更新用户数据
     *  0 新增
     *  1 打开
     *  2 更新
     */
    
    if ([[LMSystemObserver getUpdateState] integerValue] != 1 ) {
        [self registerInstallOrOpen:[LMInstallRequest class]];
    }else{
        [self registerInstallOrOpen:[LMOpenRequest class]];
    }
}

//第一次安装或打开
- (void)registerInstallOrOpen:(Class)clazz {
  callbackWithStatus initSessionCallback = ^(BOOL success, NSError *error) {
      
    
      
    if (error) {
      [self handleInitFailure:error];
    } else {
      [self handleInitSuccess];
    }
  };

  if ([LMSystemObserver getOSVersion].integerValue >= 9 && self.useCookieBasedMatching) {
    [[LMStrongMatchHelper strongMatchHelper] createStrongMatchWithLinkedMEKey:self.linkedMeKey];
  }
    
    if ([self.requestQueue removeInstallOrOpen]){
        self.networkCount = 0;
    }

  // 如果没有打开或安装请求往队列中添加一个
  if (![self.requestQueue containsInstallOrOpen]) {
    LMOpenRequest *req = [[clazz alloc] initWithCallback:initSessionCallback];
      [self insertRequestAtFront:req];
  }
  // 如果队列中有任务确保任务在最前面
  // 确保请求和回调关联
  // 如果应用被中止Open/Install进入等待状态
  else {
    LMOpenRequest *req =
        [self.requestQueue moveInstallOrOpenToFront:self.networkCount];
    req.callback = initSessionCallback;
  }

  [self processNextQueueItem];
}


// 处理初始化成功
- (void)handleInitSuccess {
    
  self.isInitialized = YES;
    
  NSDictionary *latestReferringParams = [self getLatestReferringParams];
  if (self.shouldCallSessionInitCallback) {
      NSString * str = [NSString stringWithFormat:@"%@",[latestReferringParams description]];
    if (self.sessionInitWithParamsCallback) {
      self.sessionInitWithParamsCallback(latestReferringParams, nil);
    }
    else if (self.sessionInitWithLinkedMEUniversalObjectCallback) {
      self.sessionInitWithLinkedMEUniversalObjectCallback([self getLatestReferringLinkedMEUniversalObject],
          [self getLatestReferringLinkedMELinkProperties], nil);
    }
  }

  if (self.shouldAutomaticallyDeepLink) {
    // Find any matched keys, then launch any controllers that match
    // TODO which one to launch if more than one match?
//    NSMutableSet *keysInParams =
//        [NSMutableSet setWithArray:[latestReferringParams allKeys]];
    NSMutableSet *keysInParams = [[NSMutableSet alloc]initWithObjects:latestReferringParams[LINKEDME_LINK_DATA_KEY_CONTROL][PARAMS_IOS_LINK], nil];
    NSSet *desiredKeysSet =
        [NSSet setWithArray:[self.deepLinkControllers allKeys]];
    [keysInParams intersectSet:desiredKeysSet];

    // If we find a matching key, configure and show the controller
    if ([keysInParams count]) {
      NSString *key = [[keysInParams allObjects] firstObject];
      UIViewController<LMDeepLinkingController> *linkedmeSharingController =
          self.deepLinkControllers[key];
      if ([linkedmeSharingController
              respondsToSelector:@selector(configureControlWithData:)]) {
        [linkedmeSharingController
            configureControlWithData:latestReferringParams[LINKEDME_LINK_DATA_KEY_METADATA]];
      } else {
        [self.preferenceHelper log:FILE_NAME
                              line:LINE_NUM
                           message:@"[LinkedME Warning] View controller does not "
                                   @"implement configureControlWithData:"];
      }
      linkedmeSharingController.deepLinkingCompletionDelegate = self;
      self.deepLinkPresentingController =
          [[[UIApplication sharedApplication].delegate window]
              rootViewController];

      if ([self.deepLinkPresentingController presentedViewController]) {
        [self.deepLinkPresentingController
            dismissViewControllerAnimated:NO
                               completion:^{
                                 [self.deepLinkPresentingController
                                     presentViewController:
                                         linkedmeSharingController
                                                  animated:YES
                                                completion:NULL];
                               }];
      } else {
        [self.deepLinkPresentingController
            presentViewController:linkedmeSharingController
                         animated:YES
                       completion:NULL];
      }
    }
  }
}

- (void)handleInitFailure:(NSError *)error {
  self.isInitialized = NO;
  if (self.shouldCallSessionInitCallback) {
    if (self.sessionInitWithParamsCallback) {
      self.sessionInitWithParamsCallback(nil, error);
    } else if (self.sessionInitWithLinkedMEUniversalObjectCallback) {
      self.sessionInitWithLinkedMEUniversalObjectCallback(nil, nil, error);
    }
  }
}


#pragma mark - LinkedMEDeepLinkingControllerCompletionDelegate methods

- (void)deepLinkingControllerCompleted {
  [self.deepLinkPresentingController dismissViewControllerAnimated:YES
                                                        completion:NULL];
}


@end
