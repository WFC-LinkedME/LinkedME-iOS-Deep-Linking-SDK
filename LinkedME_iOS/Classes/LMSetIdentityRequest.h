//
//  LMSetIdentityRequest.h
//  iOS-Deep-Linking-SDK
//
//  Created on 5/22/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LinkedME.h"
#import "LMServerRequest.h"

//设置请求身份
@interface LMSetIdentityRequest : LMServerRequest

- (id)initWithUserId:(NSString *)userId callback:(callbackWithParams)callback;

@end
