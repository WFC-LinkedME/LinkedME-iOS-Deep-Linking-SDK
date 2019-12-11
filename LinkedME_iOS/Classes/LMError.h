//
//  LMError.h
//  iOS-Deep-Linking-SDK
//
//  Created on 11/17/14.
//  Copyright (c) 2014 Bindx. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const LMErrorDomain;

enum {
    LKMEInitError = 1000,
    LKMEDuplicateResourceError,  //重复的资源错误
    LKMEBadRequestError,         //错误请求
    LKMEServerProblemError,      //服务器错误
    LKMENilLogError,             //日志错误
    LKMEVersionError             //版本错误
};

@interface LMError : NSObject

@end
