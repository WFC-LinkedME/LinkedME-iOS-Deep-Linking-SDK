//
//  LMSpotlightUrlRequest.h
//  iOS-Deep-Linking-SDK
//
//  Created on 7/23/15.
//  Copyright © 2015 Bindx. All rights reserved.
//

#import "LMShortUrlRequest.h"

@interface LMSpotlightUrlRequest : LMShortUrlRequest

- (id)initWithParams:(NSDictionary *)params callback:(callbackWithParams)callback;

@end
