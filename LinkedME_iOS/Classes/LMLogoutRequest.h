//
//  LMLogoutRequest.h
//  iOS-Deep-Linking-SDK
//
//  Created on 5/22/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMServerRequest.h"
#import "LinkedME.h"


//注销请求

@interface LMLogoutRequest : LMServerRequest

- (id)initWithCallback:(callbackWithStatus)callback;

@end
