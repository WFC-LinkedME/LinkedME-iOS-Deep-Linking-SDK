//
//  LMSystemObserver.m
//  iOS-Deep-Linking-SDK
//
//  Created on 6/5/14.
//  Copyright (c) 2014 Bindx. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <sys/utsname.h>
#import "LMPreferenceHelper.h"
#import "LMSystemObserver.h"
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "LMDeviceInfo.h"
#import "LMKeychain.h"
#import <Security/Security.h>


NSUInteger const DEVICE_ID_TYPE_NONE=20;
NSUInteger const DEVICE_ID_TYPE_UUID=21;
NSUInteger const DEVICE_ID_TYPE_IDFA=22;
NSUInteger const DEVICE_ID_TYPE_IDFV=24;


@implementation LMSystemObserver

+ (NSString *)getUniqueHardwareId:(BOOL *)isReal andIsDebug:(BOOL)debug {
    NSString *uid = nil;
    *isReal = YES;
    
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass && !debug) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        uid = [uuid UUIDString];
    }
    
    if (!uid && NSClassFromString(@"UIDevice") && !debug) {
        uid = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    
    if (!uid) {
        uid = [[NSUUID UUID] UUIDString];
        *isReal = NO;
    }
    
    return uid;
}

+ (LMDeviceInfo *)getUniqueHardwareIdAndType:(BOOL *)isReal andIsDebug:(BOOL)debug{
    LMDeviceInfo * result = [[LMDeviceInfo alloc]init];
    result.deviceType = DEVICE_ID_TYPE_NONE;
    NSString *uid = nil;
    *isReal = YES;
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass && !debug) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        uid = [uuid UUIDString];
        result.deviceId=uid;
        result.deviceType=DEVICE_ID_TYPE_IDFA;
    }
    
    if (!uid && NSClassFromString(@"UIDevice") && !debug) {
        uid = [[UIDevice currentDevice].identifierForVendor UUIDString];
        //检测KeyChian中是否有UDID如果有就从KeyChain中取
        if ([[LMKeychain load:@"udid"] length]>1) {
            result.deviceId = [LMKeychain load:@"udid"];
        }else{
            result.deviceId=uid;
            [LMKeychain save:@"udid" data:uid];
        }
        result.deviceType=DEVICE_ID_TYPE_IDFV;
    }
    
    if (!uid) {
        uid = [[NSUUID UUID] UUIDString];
        *isReal = NO;
        result.deviceId=uid;
        result.deviceType=DEVICE_ID_TYPE_UUID;
    }
    return result;
}

+ (NSString *)getIDFA {
    NSString *idfa = nil;
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *advertisingIdentifier = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        idfa = [advertisingIdentifier UUIDString];
    }
    return idfa;
}

+ (NSString *)getIDFV{
    NSString* uid = [[UIDevice currentDevice].identifierForVendor UUIDString];
    //检测KeyChian中是否有UDID如果有就从KeyChain中取
    if ([[LMKeychain load:@"udid"] length]>1) {
        return [LMKeychain load:@"udid"];
    }else{
        return uid;
        [LMKeychain save:@"udid" data:uid];
    }
}

+ (BOOL)adTrackingSafe {
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingEnabledSelector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL enabled = ((BOOL (*)(id, SEL))[sharedManager methodForSelector:advertisingEnabledSelector])(sharedManager, advertisingEnabledSelector);
        return enabled;
    }
    return YES;
}

+ (NSString *)getDefaultUriScheme {
    NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    
    for (NSDictionary *urlType in urlTypes) {
        NSArray *urlSchemes = [urlType objectForKey:@"CFBundleURLSchemes"];
        for (NSString *uriScheme in urlSchemes) {
            BOOL isFBScheme = [uriScheme hasPrefix:@"fb"];
            BOOL isDBScheme = [uriScheme hasPrefix:@"db"];
            BOOL isPinScheme = [uriScheme hasPrefix:@"pin"];
            
            // Don't use the schemes set aside for other integrations.
            if (!isFBScheme && !isDBScheme && !isPinScheme) {
                return uriScheme;
            }
        }
    }
    
    return nil;
}

+ (NSString *)getAppVersion {
    
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)getBundleID {
    return [[NSBundle mainBundle] bundleIdentifier];
}

+ (NSString *)getTestID{
    return  [LMKeychain load:@"udid"];
}

+ (NSString *)getTeamIdentifier {
    NSString *teamWithDot = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppIdentifierPrefix"];
    if (teamWithDot.length) {
        return [teamWithDot substringToIndex:([teamWithDot length] - 1)];
    }
    return nil;
}

//运营商
+ (NSString *)getCarrier {
    NSString *carrierName = nil;
    
    Class CTTelephonyNetworkInfoClass = NSClassFromString(@"CTTelephonyNetworkInfo");
    if (CTTelephonyNetworkInfoClass) {
        id networkInfo = [[CTTelephonyNetworkInfoClass alloc] init];
        SEL subscriberCellularProviderSelector = NSSelectorFromString(@"subscriberCellularProvider");
        
        id carrier = ((id (*)(id, SEL))[networkInfo methodForSelector:subscriberCellularProviderSelector])(networkInfo, subscriberCellularProviderSelector);
        if (carrier) {
            SEL carrierNameSelector = NSSelectorFromString(@"carrierName");
            carrierName = ((NSString* (*)(id, SEL))[carrier methodForSelector:carrierNameSelector])(carrier, carrierNameSelector);
        }
    }
    
    return carrierName;
}

+ (NSString *)getLinkedME {
    return @"Apple";
}

+ (NSString *)getModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (BOOL)isSimulator {
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *device;
    if ([LMSystemObserver getOSVersion].integerValue >= 9) {
        device = currentDevice.name;
    }
    else {
        device = currentDevice.model;
    }
    return [device rangeOfString:@"Simulator"].location != NSNotFound;
}

+ (NSString *)getDeviceName {
    if ([LMSystemObserver isSimulator]) {
        struct utsname name;
        uname(&name);
        return [NSString stringWithFormat:@"%@ %s", [[UIDevice currentDevice] name], name.nodename];
    } else {
        return [[UIDevice currentDevice] name];
    }
}

+ (NSNumber *)getUpdateState {
    NSString *storedAppVersion = [LMPreferenceHelper preferenceHelper].appVersion;
    NSString *currentAppVersion = [LMSystemObserver getAppVersion];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // for creation date
    NSURL *documentsDirRoot = [[manager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSDictionary *documentsDirAttributes = [manager attributesOfItemAtPath:documentsDirRoot.path error:nil];
    NSDate *creationDate = [documentsDirAttributes fileCreationDate];
    
    // for modification date
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSDictionary *bundleAttributes = [manager attributesOfItemAtPath:bundleRoot error:nil];
    NSDate *modificationDate = [bundleAttributes fileModificationDate];
    
    // No stored version
    if (!storedAppVersion) {
        // Modification and Creation date are more than 24 hours' worth of seconds different indicates
        // an update. This would be the case that they were installing a new version of the app that was
        // adding LinkedME for the first time, where we don't already have an NSUserDefaults value.
        if (ABS([modificationDate timeIntervalSinceDate:creationDate]) > 86400) {
            return @2;
        }
        
        // If we don't have one of the previous dates, or they're less than 60 apart,
        // we understand this to be an install.
        return @0;
    }
    // Have a stored version, but it isn't the same as the current value indicates an update
    else if (![storedAppVersion isEqualToString:currentAppVersion]) {
        return @2;
    }
    
    // Otherwise, we have a stored version, and it is equal.
    // Not an update, not an install.
    return @1;
}

+ (void)setUpdateState {
    NSString *currentAppVersion = [LMSystemObserver getAppVersion];
    [LMPreferenceHelper preferenceHelper].appVersion = currentAppVersion;
}

+ (NSString *)getOS {
    return @"iOS";
}

+ (NSString *)getOSVersion {
    UIDevice *device = [UIDevice currentDevice];
    return [device systemVersion];
}

+ (NSNumber *)getScreenWidth {
    UIScreen *mainScreen = [UIScreen mainScreen];
    float scaleFactor = mainScreen.scale;
    CGFloat width = mainScreen.bounds.size.width * scaleFactor;
    return [NSNumber numberWithInteger:(NSInteger)width];
}

+ (NSNumber *)getScreenHeight {
    UIScreen *mainScreen = [UIScreen mainScreen];
    float scaleFactor = mainScreen.scale;
    CGFloat height = mainScreen.bounds.size.height * scaleFactor;
    return [NSNumber numberWithInteger:(NSInteger)height];
}

+ (NSString *)getTimestamp{
    //    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    //    return [NSString stringWithFormat:@"%d",recordTime];
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a=[dat timeIntervalSince1970]*1000;
    NSString *timeString = [NSString stringWithFormat:@"%.f", a];
    return timeString;
}

+ (NSString*)identifierByKeychain{
    //该类方法没有线程保护，所以可能因异步而导致创建出不同的设备唯一ID，故而增加此线程锁！
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        NSString* service = @"CreateDeviceIdentifierByKeychain";
        NSString* account = @"VirtualDeviceIdentifier";
        //获取iOS系统推荐的设备唯一ID
        NSString* recommendDeviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        recommendDeviceIdentifier = [recommendDeviceIdentifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSMutableDictionary* queryDic = [NSMutableDictionary dictionary];
        [queryDic setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [queryDic setObject:service forKey:(__bridge id)kSecAttrService];
        [queryDic setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrSynchronizable];
        [queryDic setObject:account forKey:(__bridge id)kSecAttrAccount];
        [queryDic setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];//默认值为kSecMatchLimitOne，表示返回结果集的第一个
        [queryDic setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
        CFTypeRef keychainPassword = NULL;
        //首先查询钥匙串是否存在对应的值，如果存在则直接返回钥匙串中的值
        OSStatus queryResult = SecItemCopyMatching((__bridge CFDictionaryRef)queryDic, &keychainPassword);
        if (queryResult == errSecSuccess)
        {
            NSString *pwd = [[NSString alloc] initWithData:(__bridge NSData * _Nonnull)(keychainPassword) encoding:NSUTF8StringEncoding];
            if ([pwd isKindOfClass:[NSString class]] && pwd.length > 0)
            {
                return pwd;
            }
            else
            {
                //如果钥匙串中的相关数据不合法，则删除对应的数据重新创建
                NSMutableDictionary* deleteDic = [NSMutableDictionary dictionary];
                [deleteDic setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
                [deleteDic setObject:service forKey:(__bridge id)kSecAttrService];
                [deleteDic setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrSynchronizable];
                [deleteDic setObject:account forKey:(__bridge id)kSecAttrAccount];
                OSStatus status = SecItemDelete((__bridge CFDictionaryRef)deleteDic);
                if (status != errSecSuccess)
                {
                    return recommendDeviceIdentifier;
                }
            }
        }
        if (recommendDeviceIdentifier.length > 0)
        {
            //创建数据到钥匙串，达到APP即使被删除也不会变更的设备唯一ID，除非系统抹除数据，否则该数据将存储在钥匙串中
            NSMutableDictionary* createDic = [NSMutableDictionary dictionary];
            [createDic setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
            [createDic setObject:service forKey:(__bridge id)kSecAttrService];
            [createDic setObject:account forKey:(__bridge id)kSecAttrAccount];
            [createDic setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrSynchronizable];//不可以使用iCloud同步钥匙串数据，否则导致同一个iCloud账户的多个设备获取的唯一ID相同
            [createDic setObject:(__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];//增加一道保险，防止钥匙串数据被同步到其他设备，保证设备ID绝对唯一。
            [createDic setObject:[recommendDeviceIdentifier dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
            OSStatus createResult = SecItemAdd((__bridge CFDictionaryRef)createDic, nil);
            if (createResult != errSecSuccess)
            {
                NSLog(@"通过钥匙串创建设备唯一ID不成功！");
            }
        }
        return recommendDeviceIdentifier;
    }
}
@end
