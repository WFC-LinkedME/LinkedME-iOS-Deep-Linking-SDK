//
//  LMAppConnect.m
//  LinkedME-iOS-Deep-Linking-Demo
//
//  Created by Bindx on 5/19/16.
//  Copyright © 2016 Bindx. All rights reserved.
//

#import "LMAppConnect.h"

#import "LMTrackingConstants.h"
#import "LMPreferenceHelper.h"
#import "LMDeviceInfo.h"
#import "LMSystemObserver.h"
#import "LMConstants.h"
//#import "LMSimulateIDFA.h"
#import "LMServerInterface.h"
#import "LMEncodingUtils.h"


static LMAppConnect *helper = nil;

@implementation LMAppConnect

+ (instancetype)shareHelper{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });    
    return helper;
}

+ (void)getWithUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock{
    [LMAppConnect getWithUrlString:url parameters:parameters kv:NO success:successBlock failure:failureBlock];
}

+ (void)getWithUrlString:(NSString *)url KvParameters:(id)parameters kv:(BOOL)k success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock{
    [LMAppConnect getWithUrlString:url parameters:parameters kv:YES success:successBlock failure:failureBlock];
}

+ (void)getWithUrlString:(NSString *)url parameters:(id)parameters kv:(BOOL)k success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock{
    [self shareHelper];
    NSMutableString *mutableUrl = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@%@",@"",url]];
    if (k) {
        if ([parameters allKeys]) {
            [mutableUrl appendString:@"?"];
            for (id key in parameters) {
                NSString *value = [[parameters objectForKey:key] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                [mutableUrl appendString:[NSString stringWithFormat:@"%@=%@&", key, value]];
            }
        }
        [[mutableUrl substringToIndex:mutableUrl.length - 1] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }else{
        [mutableUrl appendString:@"?"];
        [mutableUrl appendString:parameters];
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:mutableUrl]];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    //TimeOut
//    config.timeoutIntervalForRequest = 60;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:helper delegateQueue:queue];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failureBlock(error);
        } else {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            successBlock(dic);
        }
    }];
    [dataTask resume];
}


+ (void)postWithUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock{
    
    NSLog(@"LMTrackingDataSDK:Start sending data.");
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    LMPreferenceHelper *preferenceHelper = [LMPreferenceHelper preferenceHelper];
    //LinkedME KEY
    [self safeSetValue:[preferenceHelper getLinkedMEKey:YES] forKey:LINKEDME_REQUEST_KEY_DEVICE_LINKEDME_KEY onDict:params];
    //Device ID
    [self safeSetValue:[LMSystemObserver identifierByKeychain] forKey:LINKEDME_REQUEST_KEY_DEVICE_ID onDict:params];
    //OS
    [self safeSetValue:@"iOS" forKey:@"os" onDict:params];
    
    //OS_Version
    [self safeSetValue:[LMSystemObserver getOSVersion] forKey:LINKEDME_REQUEST_KEY_OS_VERSION onDict:params];
    
    //device_model
    [self safeSetValue:[LMSystemObserver getModel] forKey:LINKEDME_REQUEST_KEY_DEVICE_MODEL onDict:params];

    //app_Version
    [self safeSetValue:[LMSystemObserver getAppVersion] forKey:LINKEDME_REQUEST_KEY_APP_VERSION onDict:params];
    
    //screen height
    [self safeSetValue:[LMSystemObserver getScreenHeight] forKey:LINKEDME_REQUEST_KEY_SCREEN_HEIGHT onDict:params];
    
    //screen width
    [self safeSetValue:[LMSystemObserver getScreenWidth] forKey:LINKEDME_REQUEST_KEY_SCREEN_WIDTH onDict:params];

    //longitude
    [self safeSetValue:@"0" forKey:@"lng" onDict:params];
    
    //latitude
    [self safeSetValue:@"0" forKey:@"lat" onDict:params];
    
    //SESSION
    [self safeSetValue:preferenceHelper.sessionID forKey:LINKEDME_REQUEST_KEY_SESSION_ID onDict:params];


    //Identity ID
    params[LINKEDME_REQUEST_KEY_LKME_IDENTITY]=preferenceHelper.identityID;
    
    //IDFV
    [self safeSetValue:[LMSystemObserver getIDFV] forKey:LINKEDME_REQUEST_KEY_OS_IDFV onDict:params];
        //时间戳
    [self safeSetValue:[LMSystemObserver getTimestamp] forKey:LINKEDME_REQUEST_KEY_OS_TIMESTAMP onDict:params];
    
    //USER_ID
    if (!([url rangeOfString:@"pay"].location == NSNotFound)||!([url rangeOfString:@"custom_point"].location == NSNotFound)) {
        if (preferenceHelper.userKey) {
            [self safeSetValue:preferenceHelper.userKey forKey:@"user_id" onDict:params];
        }
    }
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self safeSetValue:obj forKey:key onDict:params];
    }];
    
    //SIGN
    [self safeSetValue: [LMEncodingUtils md5Encode:[LMAppConnect parseParams:parameters]] forKey:@"sign" onDict:params];
    
    //开始请求接口
    [self postWithUrlString:url parameters:params jsonType:NO success:successBlock failure:failureBlock];
}

+ (void)postWithUrlString:(NSString *)url jsonStringParameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock{
    [LMAppConnect postWithUrlString:url parameters:parameters jsonType:YES success:successBlock failure:failureBlock];
}

+ (void)postWithUrlString:(NSString *)url parameters:(id)parameters jsonType:(BOOL)bl success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock{
    [self shareHelper];
    
    NSURL *nsurl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",@"",url]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    //设置请求方式
    request.HTTPMethod = @"POST";
    NSString *postStr = nil;
    //设置请求体
    if (bl) {
        postStr = [LMAppConnect JsonModel:parameters];
    }else{
        postStr = [LMAppConnect parseParams:parameters];
    }
    
    request.HTTPBody = [postStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:helper delegateQueue:queue];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failureBlock(error);
        } else {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            successBlock(dic);
            NSLog(@"LMTrackingDataSDK:Send data success!");
        }
    }];
    [dataTask resume];
}

#pragma mark - NSURLSessionDelegate 代理方法

//主要就是处理HTTPS请求的
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    NSURLProtectionSpace *protectionSpace = challenge.protectionSpace;
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = protectionSpace.serverTrust;
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

//把NSDictionary解析成post格式的NSString字符串
+ (NSString *)parseParams:(NSDictionary *)params{
    NSString *keyValueFormat;
    NSMutableString *result = [NSMutableString new];
    NSMutableArray *array = [NSMutableArray new];
    //实例化一个key枚举器用来存放dictionary的key
    NSEnumerator *keyEnum = [params keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        keyValueFormat = [NSString stringWithFormat:@"%@=%@&", key, [params valueForKey:key]];
        [result appendString:keyValueFormat];
        [array addObject:keyValueFormat];
    }
    return result;
}

/**
 *  NSDicionary 转 JSON串
 *
 *  @param dictModel 传入字典
 *
 *  @return 输出JSON串
 */
+(NSString *)JsonModel:(NSDictionary *)dictModel{
    if ([NSJSONSerialization isValidJSONObject:dictModel]){
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dictModel options:0 error:nil];
        NSString * jsonStr = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonStr;
    }
    return nil;
}

+ (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

@end
