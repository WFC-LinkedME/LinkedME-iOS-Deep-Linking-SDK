//
//  LMServerInterface.m
//  iOS-Deep-Linking-SDK
//
//  Created on 6/6/14.
//  Copyright (c) 2014 Bindx. All rights reserved.
//

#import "LMServerInterface.h"
#import "LKMEConfig.h"
#import "LMEncodingUtils.h"
#import "LMError.h"
#import <CoreFoundation/CFBinaryHeap.h>

@implementation LMServerInterface

#pragma mark - GET methods

- (void)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key callback:(LMServerCallback)callback {
    [self getRequest:params url:url key:key retryNumber:0 log:YES callback:callback];
}

- (void)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key log:(BOOL)log callback:(LMServerCallback)callback {
    [self getRequest:params url:url key:key retryNumber:0 log:log callback:callback];
}

- (void)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key retryNumber:(NSInteger)retryNumber log:(BOOL)log callback:(LMServerCallback)callback {
    NSURLRequest *request = [self prepareGetRequest:params url:url key:key retryNumber:retryNumber log:log];

    [self genericHTTPRequest:request retryNumber:retryNumber log:log callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return [self prepareGetRequest:params url:url key:key retryNumber:++lastRetryNumber log:log];
    }];
}

- (LMServerResponse *)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key {
    return [self getRequest:params url:url key:key log:YES];
}

- (LMServerResponse *)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key log:(BOOL)log {
    NSURLRequest *request = [self prepareGetRequest:params url:url key:key retryNumber:0 log:log];
    return [self genericHTTPRequest:request log:log];
}

#pragma mark - POST methods

- (void)postRequest:(NSDictionary *)post url:(NSString *)url key:(NSString *)key callback:(LMServerCallback)callback {
    [self postRequest:post url:url retryNumber:0 key:key log:YES callback:callback];
}

- (void)postRequest:(NSDictionary *)post url:(NSString *)url key:(NSString *)key log:(BOOL)log callback:(LMServerCallback)callback {
    [self postRequest:post url:url retryNumber:0 key: key log:log callback:callback];
}

- (void)postRequest:(NSDictionary *)post url:(NSString *)url retryNumber:(NSInteger)retryNumber key:(NSString *)key log:(BOOL)log callback:(LMServerCallback)callback {
    NSURLRequest *request = [self preparePostRequest:post url:url key:key retryNumber:retryNumber log:log];

    [self genericHTTPRequest:request retryNumber:retryNumber log:log callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return [self preparePostRequest:post url:url key:key retryNumber:++lastRetryNumber log:log];
    }];
}

- (LMServerResponse *)postRequest:(NSDictionary *)post url:(NSString *)url key:(NSString *)key log:(BOOL)log {
    NSURLRequest *request = [self preparePostRequest:post url:url key:key retryNumber:0 log:log];
    return [self genericHTTPRequest:request log:log];
}


#pragma mark - Generic requests

- (void)genericHTTPRequest:(NSURLRequest *)request log:(BOOL)log callback:(LMServerCallback)callback {
    [self genericHTTPRequest:request retryNumber:0 log:log callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return request;
    }];
}

- (void)genericHTTPRequest:(NSURLRequest *)request retryNumber:(NSInteger)retryNumber log:(BOOL)log callback:(LMServerCallback)callback retryHandler:(NSURLRequest *(^)(NSInteger))retryHandler {
    
    
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request.copy completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
#else
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
#endif

         LMServerResponse *serverResponse = [self processServerResponse:response data:responseData error:error log:log];

        NSInteger status = [serverResponse.statusCode integerValue];


        
//        BOOL isRetryableStatusCode = status >= 500;
        BOOL isRetryableStatusCode = status >= 500 || status < 0;
        
        // Retry the request if appropriate
        if (retryNumber < self.preferenceHelper.retryCount && isRetryableStatusCode) {

            dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, self.preferenceHelper.retryInterval * NSEC_PER_SEC);
                dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
                if (log) {
                    [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"用URL重放请求：%@", request.URL.relativePath];
                }
                // Create the next request
                NSURLRequest *retryRequest = retryHandler(retryNumber);
                [self genericHTTPRequest:retryRequest retryNumber:(retryNumber + 1) log:log callback:callback retryHandler:retryHandler];
                NSLog(@"网络链接失败，正在进行第%ld次重试,重试间隔时间%.f秒",(long)retryNumber +1,self.preferenceHelper.retryInterval);
            });
        }
        else if (callback) {
            // Wrap up bad statuses w/ specific error messages
            if (status >= 500) {
                error = [NSError errorWithDomain:LMErrorDomain code:LKMEServerProblemError userInfo:@{ NSLocalizedDescriptionKey: @"无法连接LinkedME服务器，请稍后再试" }];
            }
            else if (status == 409) {
                error = [NSError errorWithDomain:LMErrorDomain code:LKMEDuplicateResourceError userInfo:@{ NSLocalizedDescriptionKey: @"具有该标识符的资源已存在" }];
            }
            else if (status >= 400) {
                NSString *errorString = [serverResponse.data objectForKey:@"error"] ?: @"无效请求！.";
                
                error = [NSError errorWithDomain:LMErrorDomain code:LKMEBadRequestError userInfo:@{ NSLocalizedDescriptionKey: errorString }];
            }
            
            if (error && log) {
                [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"％@错误导致请求无法完成:%@", request.URL.absoluteString, error.localizedDescription];
            }
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(serverResponse, error);
            });
        }
    }];
    [task resume];
    [session finishTasksAndInvalidate];
#else
            callback(serverResponse, error);
        }
    }];
#endif
}

- (LMServerResponse *)genericHTTPRequest:(NSURLRequest *)request log:(BOOL)log {
    __block NSURLResponse *_response = nil;
    __block NSError *_error = nil;
    __block NSData *_respData = nil;
    
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable urlResp, NSError * _Nullable error) {
        _response = urlResp;
        _error = error;
        _respData = data;
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    [session finishTasksAndInvalidate];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
#else
    _respData = [NSURLConnection sendSynchronousRequest:request returningResponse:&_response error:&_error];
#endif
    return [self processServerResponse:_response data:_respData error:_error log:log];
}


#pragma mark - Internals

- (NSURLRequest *)prepareGetRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key retryNumber:(NSInteger)retryNumber log:(BOOL)log {
    NSDictionary *preparedParams = [self prepareParamDict:params key:key retryNumber:retryNumber];
    
    NSString *requestUrlString = [NSString stringWithFormat:@"%@%@", url, [LMEncodingUtils encodeDictionaryToQueryString:preparedParams]];
    
    if (log) {
        [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"using url = %@", url];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:requestUrlString]];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    return request;
}

- (NSURLRequest *)preparePostRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key retryNumber:(NSInteger)retryNumber log:(BOOL)log {
    NSDictionary *preparedParams = [self prepareParamDict:params key:key retryNumber:retryNumber];

    NSData *postData = [LMEncodingUtils encodeDictionaryToJsonData:preparedParams];
    
    NSString *para = [LMServerInterface parseParams:preparedParams];
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    if (log) {
        [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"using url = %@", url];
        //is modified han
        NSError *error;
        NSData *testData = [NSJSONSerialization dataWithJSONObject:preparedParams options:NSJSONWritingPrettyPrinted error:&error];
        NSString *dataStr = [[NSString alloc] initWithData:testData encoding:NSUTF8StringEncoding];
         [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"body = %@", dataStr];
//        [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"body = %@", preparedParams];
//        NSDictionary *dic = [
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setTimeoutInterval:self.preferenceHelper.timeout];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
//    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[para dataUsingEncoding:NSUTF8StringEncoding]];
    
    return request;
}

- (NSDictionary *)prepareParamDict:(NSDictionary *)params key:(NSString *)key retryNumber:(NSInteger)retryNumber {
    NSMutableDictionary *fullParamDict = [[NSMutableDictionary alloc] init];
    [fullParamDict addEntriesFromDictionary:params];
    fullParamDict[@"sdk_version"] = [NSString stringWithFormat:@"ios%@", SDK_VERSION];
    fullParamDict[@"retry_times"] = @(retryNumber);
    fullParamDict[@"linkedme_key"] = key;
    NSMutableArray * values=[[NSMutableArray alloc] init];
    for (NSValue * obj in [fullParamDict allValues]) {
        [values addObject:[obj description]];
    }
    NSArray * array = [values sortedArrayUsingSelector:@selector(compare:)];
    NSString * prepareData = [array componentsJoinedByString:@"&"];
    NSString * prepareDataFinished = [prepareData stringByAppendingString:[self getCurrentTime]];
    fullParamDict[@"sign"]= [LMEncodingUtils md5Encode:prepareDataFinished];
    
    return fullParamDict;
}

- (NSString *)getCurrentTime{
    NSTimeInterval time=[[NSDate date] timeIntervalSince1970]*1000;
    double i=time;      //NSTimeInterval返回的是double类型
    return [NSString stringWithFormat:@"%.llf",i];
}

- (LMServerResponse *)processServerResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error log:(BOOL)log {
    LMServerResponse *serverResponse = [[LMServerResponse alloc] init];

    if (!error) {
        serverResponse.statusCode = @([(NSHTTPURLResponse *)response statusCode]);
        serverResponse.data = [LMEncodingUtils decodeJsonDataToDictionary:data];
    }
    else {
        serverResponse.statusCode = @(error.code);
        serverResponse.data = error.userInfo;
    }

    if (log) {
        [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"LKMEServerinterface  returned = %@", serverResponse];
    }
    
    return serverResponse;
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

@end
