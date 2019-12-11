//
//  LMRegisterViewRequest.h
//  iOS-Deep-Linking-SDK
//
//  Created on 10/16/15.
//  Copyright © 2015 Bindx. All rights reserved.
//

#import "LMServerRequest.h"
#import "LinkedME.h"

//注册view

@interface LMRegisterViewRequest : LMServerRequest

- (id)initWithParams:(NSDictionary *)params andCallback:(callbackWithParams)callback;

@end
