//
//  LMPreferenceHelper.m
//  iOS-Deep-Linking-SDK
//
//  Created on 6/6/14.
//  Copyright (c) 2014 Bindx. All rights reserved.
//

#import "LMPreferenceHelper.h"
#import "LMSystemObserver.h"
#import "LMEncodingUtils.h"
#import "LKMEConfig.h"
#import "LinkedME.h"

static const NSTimeInterval DEFAULT_TIMEOUT = 5.5;
static const NSTimeInterval DEFAULT_RETRY_INTERVAL = 0;
static const NSInteger DEFAULT_RETRY_COUNT = 3;

NSString * const LINKEDME_PREFS_FILE = @"linkedmePreferences";

NSString * const LINKEDME_PREFS_KEY_APP_KEY = @"linkedme_app_key";
NSString * const LINKEDME_PREFS_KEY_APP_VERSION = @"linkedme_app_version";
NSString * const LINKEDME_PREFS_KEY_APP_USER_ID = @"user_id";
NSString * const LINKEDME_PREFS_KEY_LAST_RUN_LKME_KEY = @"linkedme_last_run_linkedme_key";
NSString * const LINKEDME_PREFS_KEY_LAST_STRONG_MATCH_DATE = @"linkedme_strong_match_created_date";
NSString * const LINKEDME_PREFS_KEY_DEVICE_FINGERPRINT_ID = @"linkedme_device_fingerprint_id";
NSString * const LINKEDME_PREFS_KEY_SESSION_ID = @"linkedme_session_id";
NSString * const LINKEDME_PREFS_KEY_IDENTITY_ID = @"linkedme_identity_id";
NSString * const LINKEDME_PREFS_KEY_IDENTITY = @"linkedme_identity";
NSString * const LINKEDME_PREFS_KEY_LINK_CLICK_IDENTIFIER = @"linkedme_link_click_identifier";
NSString * const LINKEDME_PREFS_KEY_SPOTLIGHT_IDENTIFIER = @"linkedme_spotlight_identifier";
NSString * const LINKEDME_PREFS_KEY_UNIVERSAL_LINK_URL = @"linkedme_universal_link_url";
NSString * const LINKEDME_PREFS_KEY_SESSION_PARAMS = @"linkedme_session_params";
NSString * const LINKEDME_PREFS_KEY_INSTALL_PARAMS = @"linkedme_install_params";
NSString * const LINKEDME_PREFS_KEY_USER_URL = @"linkedme_user_url";
NSString * const LINKEDME_PREFS_KEY_IS_REFERRABLE = @"linkedme_is_referrable";
NSString * const LINKEDME_PREFS_KEY_LINKEDME_UNIVERSAL_LINK_DOMAINS = @"LinkedME_iOS_Example";
NSString * const LINKEDME_REQUEST_KEY_EXTERNAL_INTENT_URI = @"external_intent_uri";

NSString * const LINKEDME_PREFS_KEY_CREDITS = @"linkedme_credits";
NSString * const LINKEDME_PREFS_KEY_CREDIT_BASE = @"linkedme_credit_base_";

NSString * const LINKEDME_PREFS_KEY_COUNTS = @"linkedme_counts";
NSString * const LINKEDME_PREFS_KEY_TOTAL_BASE = @"linkedme_total_base_";
NSString * const LINKEDME_PREFS_KEY_UNIQUE_BASE = @"linkedme_unique_base_";



NSString * const LKME_REQUEST_KEY_EXTERNAL_INTENT_URI = @"extra_uri_data";

@interface LMPreferenceHelper ()

@property (strong, nonatomic) NSMutableDictionary *persistenceDict;
@property (strong, nonatomic) NSMutableDictionary *countsDictionary;
@property (strong, nonatomic) NSMutableDictionary *creditsDictionary;
@property (assign, nonatomic) BOOL isUsingLiveKey;

@end

@implementation LMPreferenceHelper

@synthesize linedMEKey = _linedMEKey,
            appKey = _appKey,
            lastRunLinkedMeKey = _lastRunLinkedMeKey,
            appVersion = _appVersion,
            deviceFingerprintID = _deviceFingerprintID,
            deviceID = _deviceID,
            sessionID = _sessionID,
            spotlightIdentifier = _spotlightIdentifier,
            identityID = _identityID,
            linkClickIdentifier = _linkClickIdentifier,
            userUrl = _userUrl,
            userKey = _userKey,
            userIdentity = _userIdentity,
            sessionParams = _sessionParams,
            installParams = _installParams,
            universalLinkUrl = _universalLinkUrl,
            externalIntentURI = _externalIntentURI,
            closeSession = _closeSession,
            isReferrable = _isReferrable,
            isDebug = _isDebug,
            disableClipboardMatch = _disableClipboardMatch,
            useHTTPS = _useHTTPS,
            disableLocation = _disableLocation,
            shouldWaitForInit = _shouldWaitForInit,
            isContinuingUserActivity = _isContinuingUserActivity,
            retryCount = _retryCount,
            retryInterval = _retryInterval,
            timeout = _timeout,
            getSafariCookice = _getSafariCookice,
            lastStrongMatchDate = _lastStrongMatchDate;

+ (LMPreferenceHelper *)preferenceHelper {
    static LMPreferenceHelper *preferenceHelper;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        preferenceHelper = [[LMPreferenceHelper alloc] init];
    });
    
    return preferenceHelper;
}

- (id)init {
    if (self = [super init]) {
        _timeout = DEFAULT_TIMEOUT;
        _retryCount = DEFAULT_RETRY_COUNT;
        _retryInterval = DEFAULT_RETRY_INTERVAL;
        _isDebug = NO;
        _disableLocation = NO;
        _explicitlyRequestedReferrable = NO;
        _isReferrable = [self readBoolFromDefaults:LINKEDME_PREFS_KEY_IS_REFERRABLE];
    }
    
    return self;
}

+ (LMPreferenceHelper *)getInstance {
    static LMPreferenceHelper *preferenceHelper;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        preferenceHelper = [[LMPreferenceHelper alloc] init];
    });
    
    return preferenceHelper;
}

- (NSOperationQueue *)persistPrefsQueue {
    static NSOperationQueue *persistPrefsQueue;
    static dispatch_once_t persistOnceToken;
    
    dispatch_once(&persistOnceToken, ^{
        persistPrefsQueue = [[NSOperationQueue alloc] init];
        persistPrefsQueue.maxConcurrentOperationCount = 1;
    });

    return persistPrefsQueue;
}

- (NSDate*) previousAppBuildDate {
    @synchronized (self) {
        NSDate *date = (NSDate*) [self readObjectFromDefaults:@"_previousAppBuildDate"];
        if ([date isKindOfClass:[NSDate class]]) return date;
        return nil;
    }
}

#pragma mark - Debug methods

- (void)log:(NSString *)filename line:(int)line message:(NSString *)format, ... {
    if (self.isDebug) {
        va_list args;
        va_start(args, format);
        NSString *log = [NSString stringWithFormat:@"[%@:%d] %@", filename, line, [[NSString alloc] initWithFormat:format arguments:args]];
        va_end(args);
        NSLog(@"%@", log);
    }
}

-(NSString *)getAPIBaseURL {
    
    return [NSString stringWithFormat:@"%@/%@/", LKME_API_BASE_URL([LMPreferenceHelper preferenceHelper].useHTTPS), LKME_API_VERSION];
}

-(NSString *)getAPIBaseURL2 {
    
    return [NSString stringWithFormat:@"%@/", LKME_API_BASE_URL([LMPreferenceHelper preferenceHelper].useHTTPS)];
}

+ (NSString *)getAPIBaseURL {
    
    return [NSString stringWithFormat:@"%@/%@/", LKME_API_BASE_URL([LMPreferenceHelper preferenceHelper].useHTTPS), LKME_API_VERSION];
}

- (NSString *)getAPIURL:(NSString *) endpoint {
    return [[self getAPIBaseURL] stringByAppendingString:endpoint];
}

-(NSString *)getSDKURL:(NSString *)endpoint{
    NSLog(@"%@",[[self  getAPIBaseURL] stringByAppendingString:[NSString stringWithFormat:@"%@/%@",LKME_API_PREFIX_SDK,endpoint]]);
    return [[self  getAPIBaseURL] stringByAppendingString:[NSString stringWithFormat:@"%@/%@",LKME_API_PREFIX_SDK,endpoint]];
}

-(NSString *)getTrackURL:(NSString *)endpoint{
//    return [[self  getAPIBaseURL2] stringByAppendingString:[NSString stringWithFormat:@"%@/%@",LKME_API_PREFIX_MONITOR,endpoint]];
    return [NSString stringWithFormat:@"%@/%@",@"http://192.168.99.169:8080/track",endpoint];

}

-(NSString *)getGameTrackURL:(NSString *)endpoint{
    return [[self  getAPIBaseURL] stringByAppendingString:[NSString stringWithFormat:@"%@/%@",LKME_API_PREFIX_GAME,endpoint]];
}

+ (NSString *)getSDKURL:(NSString *)endpoint{
    return [[self  getAPIBaseURL] stringByAppendingString:[NSString stringWithFormat:@"%@/%@",LKME_API_PREFIX_SDK,endpoint]];
    
}
-(NSString *)getUberURL:(NSString *)endpoint{
    
//    return [[self  getAPIBaseURL] stringByAppendingString:[NSString stringWithFormat:@"%@/%@",LKME_API_PREFIX_UBER,endpoint]];
    return [[self  getAPIBaseURL] stringByAppendingString:[NSString stringWithFormat:@"%@",endpoint]];
}

#pragma mark - Preference Storage


- (NSString *)appKey {
    if (!_appKey) {
        _appKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:LINKEDME_PREFS_KEY_APP_KEY];
    }
    
    return _appKey;
}

- (void)setAppKey:(NSString *)appKey {
    NSLog(@"Usage of App Key is deprecated, please move toward using a LinkedME key");
    
    if (![_appKey isEqualToString:appKey]) {
        _appKey = appKey;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_APP_KEY value:appKey];
    }
}


- (NSString *)getLinkedMEKey:(BOOL)isLive {
    // Already loaded a key, and it's the same state (live/test)
    if (_linedMEKey && isLive == self.isUsingLiveKey) {
        return _linedMEKey;
    }
    
    self.isUsingLiveKey = isLive;
#warning 修改key
    id ret = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"linkedme_key"];
    if (ret) {
        if ([ret isKindOfClass:[NSString class]]) {
            self.linedMEKey = ret;
        }
        else if ([ret isKindOfClass:[NSDictionary class]]) {
            self.linedMEKey = isLive ? ret[@"live"] : ret[@"test"];
        }
    }
    
    return _linedMEKey;
}

- (void)setLinedMEKey:(NSString *)linkedMEKey {
    _linedMEKey = linkedMEKey;
}

- (NSString *)lastRunLinkedMeKey {
    if (!_lastRunLinkedMeKey) {
        _lastRunLinkedMeKey = [self readStringFromDefaults:LINKEDME_PREFS_KEY_LAST_RUN_LKME_KEY];
    }
    
    return _lastRunLinkedMeKey;
}

- (void)setLastRunLinkedMeKey:(NSString *)lastRunLinkedMEKey {
    if (![_lastRunLinkedMeKey isEqualToString:lastRunLinkedMEKey]) {
        _lastRunLinkedMeKey = lastRunLinkedMEKey;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_LAST_RUN_LKME_KEY value:lastRunLinkedMEKey];
    }
}

- (NSDate *)lastStrongMatchDate {
    if (!_lastStrongMatchDate) {
        _lastStrongMatchDate = (NSDate *)[self readObjectFromDefaults:LINKEDME_PREFS_KEY_LAST_STRONG_MATCH_DATE];
    }
    
    return _lastStrongMatchDate;
}

- (void)setLastStrongMatchDate:(NSDate *)lastStrongMatchDate {
    if (![_lastStrongMatchDate isEqualToDate:lastStrongMatchDate]) {
        _lastStrongMatchDate = lastStrongMatchDate;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_LAST_STRONG_MATCH_DATE value:lastStrongMatchDate];
    }
}

- (NSString *)appVersion {
    if (!_appVersion) {
        _appVersion = [self readStringFromDefaults:LINKEDME_PREFS_KEY_APP_VERSION];
    }
    
    return _appVersion;
}

- (void)setAppVersion:(NSString *)appVersion {
    if (![_appVersion isEqualToString:appVersion]) {
        _appVersion = appVersion;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_APP_VERSION value:appVersion];
    }
}

- (NSString *)deviceFingerprintID {
    if (!_deviceFingerprintID) {
        _deviceFingerprintID = [self readStringFromDefaults:LINKEDME_PREFS_KEY_DEVICE_FINGERPRINT_ID];
    }
    
    return _deviceFingerprintID;
}

- (void)setDeviceFingerprintID:(NSString *)deviceFingerprintID {
    
    if (deviceFingerprintID && ![_deviceFingerprintID isEqualToString:deviceFingerprintID]) {
        _deviceFingerprintID = deviceFingerprintID;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_DEVICE_FINGERPRINT_ID value:deviceFingerprintID];
    }
}

- (NSString *)deviceID {
    return [LMSystemObserver identifierByKeychain];
}

- (NSString *)sessionID {
    if (!_sessionID) {
        _sessionID = [self readStringFromDefaults:LINKEDME_PREFS_KEY_SESSION_ID];
    }
    
    return _sessionID;
}

- (void)setSessionID:(NSString *)sessionID {
    
    NSString *sessionIDSTR = [NSString stringWithFormat:@"%@",sessionID];
    if (![_sessionID isEqualToString:sessionIDSTR]) {
        _sessionID = sessionID;
        
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_SESSION_ID value:sessionID];
    }
}

- (NSString *)identityID {
    if (!_identityID) {
        _identityID = [self readStringFromDefaults:LINKEDME_PREFS_KEY_IDENTITY_ID];
    }
    
    return _identityID;
}

- (void)setIdentityID:(NSString *)identityID {

    NSString *identityIDStr = [NSString stringWithFormat:@"%@",_identityID];
    if (![identityIDStr isEqualToString:identityID]) {
        _identityID = identityID;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_IDENTITY_ID value:identityID];
    }
}


- (NSString *)userIdentity {
    if (!_userIdentity) {
        _userIdentity = [self readStringFromDefaults:LINKEDME_PREFS_KEY_IDENTITY];
    }

    return _userIdentity;
}

- (void)setUserIdentity:(NSString *)userIdentity {
    if (![_userIdentity isEqualToString:userIdentity]) {
        _userIdentity = userIdentity;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_IDENTITY value:userIdentity];
    }
}

- (NSString *)linkClickIdentifier {
    if (!_linkClickIdentifier) {
        _linkClickIdentifier = [self readStringFromDefaults:LINKEDME_PREFS_KEY_LINK_CLICK_IDENTIFIER];
    }

    return _linkClickIdentifier;
}

- (void)setLinkClickIdentifier:(NSString *)linkClickIdentifier {
    if (![_linkClickIdentifier isEqualToString:linkClickIdentifier]) {
        _linkClickIdentifier = linkClickIdentifier;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_LINK_CLICK_IDENTIFIER value:linkClickIdentifier];
    }
}

- (NSString *)spotlightIdentifier {
    if (!_spotlightIdentifier) {
        _spotlightIdentifier = [self readStringFromDefaults:LINKEDME_PREFS_KEY_SPOTLIGHT_IDENTIFIER];
    }
    
    return _spotlightIdentifier;
}

- (void)setSpotlightIdentifier:(NSString *)spotlightIdentifier {
    if (![_spotlightIdentifier isEqualToString:spotlightIdentifier]) {
        _spotlightIdentifier = spotlightIdentifier;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_SPOTLIGHT_IDENTIFIER value:spotlightIdentifier];
    }
}

- (NSString *)externalIntentURI {
    if (!_externalIntentURI) {
        _externalIntentURI = [self readStringFromDefaults:LINKEDME_REQUEST_KEY_EXTERNAL_INTENT_URI];
    }
    return _externalIntentURI;
}

- (void)setExternalIntentURI:(NSString *)externalIntentURI {
    if (![_externalIntentURI isEqualToString:externalIntentURI]) {
        _externalIntentURI = externalIntentURI;
        [self writeObjectToDefaults:LINKEDME_REQUEST_KEY_EXTERNAL_INTENT_URI value:externalIntentURI];
    }
}


- (NSString *)closeSession {
    if (!_closeSession) {
        _closeSession = [self readStringFromDefaults:@"closeSession"];
    }
    return _closeSession;
}

- (void)setCloseSession:(NSString *)closeSession{
    if (![_closeSession isEqualToString:closeSession]) {
        _closeSession = closeSession;
        [self writeObjectToDefaults:@"closeSession" value:closeSession];
    }
}

- (NSString *)universalLinkUrl {
    if (!_universalLinkUrl) {
        _universalLinkUrl = [self readStringFromDefaults:LINKEDME_PREFS_KEY_UNIVERSAL_LINK_URL];
    }
    return _universalLinkUrl;
}

- (void)setUniversalLinkUrl:(NSString *)universalLinkUrl {
    if (![_universalLinkUrl isEqualToString:universalLinkUrl]) {
        _universalLinkUrl = universalLinkUrl;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_UNIVERSAL_LINK_URL value:universalLinkUrl];
    }
}

- (NSString *)sessionParams {
    if (_sessionParams) {
        _sessionParams = [self readStringFromDefaults:LINKEDME_PREFS_KEY_SESSION_PARAMS];

    }
    
    return _sessionParams;
}

- (void)setSessionParams:(NSString *)sessionParams {
    if (![_sessionParams isEqualToString:sessionParams]) {
        _sessionParams = sessionParams;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_SESSION_PARAMS value:sessionParams];
    }
}

- (NSString *)installParams {
    if (!_installParams) {
        id installParamsFromCache = [self readStringFromDefaults:LINKEDME_PREFS_KEY_INSTALL_PARAMS];
        if ([installParamsFromCache isKindOfClass:[NSString class]]) {
            _installParams = [self readStringFromDefaults:LINKEDME_PREFS_KEY_INSTALL_PARAMS];
        }
        else if ([installParamsFromCache isKindOfClass:[NSDictionary class]]) {
            [self writeObjectToDefaults:LINKEDME_PREFS_KEY_INSTALL_PARAMS value:nil];
        }
    }
    
    return _installParams;
}

- (void)setInstallParams:(NSString *)installParams {
    if ([installParams isKindOfClass:[NSDictionary class]]) {
        _installParams = [LMEncodingUtils encodeDictionaryToJsonString:(NSDictionary *)installParams];
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_INSTALL_PARAMS value:_installParams];
        return;
    }
    
    if (![_installParams isEqualToString:installParams]) {
        _installParams = installParams;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_INSTALL_PARAMS value:installParams];
    }
}

- (NSString *)userUrl {
    if (!_userUrl) {
        _userUrl = [self readStringFromDefaults:LINKEDME_PREFS_KEY_USER_URL];
    }
    
    return _userUrl;
}

- (void)setUserUrl:(NSString *)userUrl {
    if (![_userUrl isEqualToString:userUrl]) {
        _userUrl = userUrl;
        [self writeObjectToDefaults:LINKEDME_PREFS_KEY_USER_URL value:userUrl];
    }
}

- (NSString *)userKey{
    if (!_userKey) {
        _userKey = [self readStringFromDefaults:@"userKey"];
    }
    return _userKey;
}

- (void)setUserKey:(NSString *)userKey{
    if (![_userKey isEqualToString:userKey]) {
        _userKey = userKey;
        [self writeObjectToDefaults:@"userKey" value:_userKey];
    }
}

- (BOOL)getSafariCookice{
    if (!_getSafariCookice) {
        _getSafariCookice = [self readStringFromDefaults:@"getSafariCookice"];
    }
    return _getSafariCookice;
}

- (void)setSafariCookice:(BOOL)status{
    if (_getSafariCookice != status) {
        [self writeBoolToDefaults:@"getSafariCookice" value:status];
    }
}

- (BOOL)useHTTPS{
    if (!_useHTTPS) {
        _useHTTPS = [self readBoolFromDefaults:@"check_https_status"];
    }
    return _useHTTPS;
}

- (void)setUseHTTPS:(BOOL)status{
//    if (_useHTTPS != status) {
        [self writeBoolToDefaults:@"check_https_status" value:status];
//    }
}

//- (BOOL)disableLocation{
//    if (!_disableLocation) {
//        _disableLocation = [self readBoolFromDefaults:@"disableLocationValue"];
//    }
//    return _disableLocation;
//}
//
//- (void)setDisableLocation:(BOOL)status{
//    [self writeBoolToDefaults:@"disableLocationValue" value:status];
//}

- (BOOL)isReferrable {
    BOOL hasIdentity = self.identityID != nil;
    
    // If referrable is set, but they already have an identity, they should only
    // still be referrable if the dev has explicitly set always referrable.
    if (_isReferrable && hasIdentity) {
        return _explicitlyRequestedReferrable;
    }
    
    // If not referrable, or no identity yet, whatever isReferrable has is fine to return.
    return _isReferrable;
}

- (void)setIsReferrable:(BOOL)isReferrable {
    if (_isReferrable != isReferrable) {
        _isReferrable = isReferrable;
        [self writeBoolToDefaults:LINKEDME_PREFS_KEY_IS_REFERRABLE value:isReferrable];
    }
}

- (void)clearUserCreditsAndCounts {
    self.creditsDictionary = [[NSMutableDictionary alloc] init];
    self.countsDictionary = [[NSMutableDictionary alloc] init];
}

- (id)getLinkedMEUniversalLinkDomains {
    NSLog(@"%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:LINKEDME_PREFS_KEY_LINKEDME_UNIVERSAL_LINK_DOMAINS]);
//    return [[[NSBundle mainBundle] infoDictionary] objectForKey:LINKEDME_PREFS_KEY_LINKEDME_UNIVERSAL_LINK_DOMAINS];
    return @"lkme.cc";
}

#pragma mark - Credit Storage

- (NSMutableDictionary *)creditsDictionary {
    if (!_creditsDictionary) {
        _creditsDictionary = [[self readObjectFromDefaults:LINKEDME_PREFS_KEY_CREDITS] mutableCopy];
        
        if (!_creditsDictionary) {
            _creditsDictionary = [[NSMutableDictionary alloc] init];
        }
    }
    
    return _creditsDictionary;
}

- (void)setCreditCount:(NSInteger)count {
    [self setCreditCount:count forBucket:@"default"];
}

- (void)setCreditCount:(NSInteger)count forBucket:(NSString *)bucket {
    self.creditsDictionary[[LINKEDME_PREFS_KEY_CREDIT_BASE stringByAppendingString:bucket]] = @(count);

    [self writeObjectToDefaults:LINKEDME_PREFS_KEY_CREDITS value:self.creditsDictionary];
}

- (void)removeCreditCountForBucket:(NSString *)bucket {
    NSMutableDictionary *dictToWrite = self.creditsDictionary;
    [dictToWrite removeObjectForKey:[LINKEDME_PREFS_KEY_CREDIT_BASE stringByAppendingString:bucket]];

    [self writeObjectToDefaults:LINKEDME_PREFS_KEY_CREDITS value:self.creditsDictionary];
}

- (NSDictionary *)getCreditDictionary {
    NSMutableDictionary *returnDictionary = [[NSMutableDictionary alloc] init];
    for(NSString *key in self.creditsDictionary) {
        NSString *cleanKey = [key stringByReplacingOccurrencesOfString:LINKEDME_PREFS_KEY_CREDIT_BASE
                                                                                     withString:@""];
        returnDictionary[cleanKey] = self.creditsDictionary[key];
    }
    return returnDictionary;
}

- (NSInteger)getCreditCount {
    return [self getCreditCountForBucket:@"default"];
}

- (NSInteger)getCreditCountForBucket:(NSString *)bucket {
    return [self.creditsDictionary[[LINKEDME_PREFS_KEY_CREDIT_BASE stringByAppendingString:bucket]] integerValue];
}

- (void)clearUserCredits {
    self.creditsDictionary = [[NSMutableDictionary alloc] init];
    [self writeObjectToDefaults:LINKEDME_PREFS_KEY_CREDITS value:self.creditsDictionary];
}

#pragma mark - Count Storage

- (NSMutableDictionary *)countsDictionary {
    if (!_countsDictionary) {
        _countsDictionary = [[self readObjectFromDefaults:LINKEDME_PREFS_KEY_COUNTS] mutableCopy];
        
        if (!_countsDictionary) {
            _countsDictionary = [[NSMutableDictionary alloc] init];
        }
    }
    
    return _countsDictionary;
}

- (void)setActionTotalCount:(NSString *)action withCount:(NSInteger)count {
    self.countsDictionary[[LINKEDME_PREFS_KEY_TOTAL_BASE stringByAppendingString:action]] = @(count);
    
    [self writeObjectToDefaults:LINKEDME_PREFS_KEY_COUNTS value:self.countsDictionary];
}

- (void)setActionUniqueCount:(NSString *)action withCount:(NSInteger)count {
    self.countsDictionary[[LINKEDME_PREFS_KEY_UNIQUE_BASE stringByAppendingString:action]] = @(count);

    [self writeObjectToDefaults:LINKEDME_PREFS_KEY_COUNTS value:self.countsDictionary];
}



#pragma mark - Writing To Persistence

- (void)writeIntegerToDefaults:(NSString *)key value:(NSInteger)value {
    self.persistenceDict[key] = @(value);
    [self persistPrefsToDisk];
}

- (void)writeBoolToDefaults:(NSString *)key value:(BOOL)value {
    self.persistenceDict[key] = @(value);
    [self persistPrefsToDisk];
}

- (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value {
    if (value) {
        self.persistenceDict[key] = value;
    }
    else {
        [self.persistenceDict removeObjectForKey:key];
    }

    [self persistPrefsToDisk];
}

- (void)persistPrefsToDisk {
    NSDictionary *persistenceDict = [self.persistenceDict copy];
    NSBlockOperation *newPersistOp = [NSBlockOperation blockOperationWithBlock:^{
        if (![NSKeyedArchiver archiveRootObject:persistenceDict toFile:[self prefsFile]]) {
            NSLog(@"[Linkedme Warning] Failed to persist preferences to disk");
        }
    }];
    [self.persistPrefsQueue addOperation:newPersistOp];
}

#pragma mark - Reading From Persistence

- (NSMutableDictionary *)persistenceDict {
    if (!_persistenceDict) {
        NSDictionary *persistenceDict = nil;
        @try {
            persistenceDict = [NSKeyedUnarchiver unarchiveObjectWithFile:[self prefsFile]];
        }
        @catch (NSException *exception) {
            NSLog(@"[Linkedme Warning] Failed to load preferences from disk");
        }

        if (persistenceDict) {
            _persistenceDict = [persistenceDict mutableCopy];
        }
        else {
            _persistenceDict = [[NSMutableDictionary alloc] init];
        }
    }
    
    return _persistenceDict;
}

- (NSObject *)readObjectFromDefaults:(NSString *)key {
    NSObject *obj = self.persistenceDict[key];
    return obj;
}

- (NSString *)readStringFromDefaults:(NSString *)key {
    id str = self.persistenceDict[key];
    
    if ([str isKindOfClass:[NSNumber class]]) {
        str = [str stringValue];
    }
    
    return str;
}

- (BOOL)readBoolFromDefaults:(NSString *)key {
    BOOL boo = [self.persistenceDict[key] boolValue];
    return boo;
}

- (NSInteger)readIntegerFromDefaults:(NSString *)key {
    NSNumber *number = self.persistenceDict[key];
    
    if (number) {
        return [number integerValue];
    }
    
    return NSNotFound;
}

- (NSString *)prefsFile {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:LINKEDME_PREFS_FILE];
}

@end
