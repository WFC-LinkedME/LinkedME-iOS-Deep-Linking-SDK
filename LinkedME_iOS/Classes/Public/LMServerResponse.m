//
//  LMServerResponse.m
//  iOS-Deep-Linking-SDK
//
//  Created on 10/10/14.
//  Copyright (c) 2014 Bindx. All rights reserved.
//

#import "LMServerResponse.h"

@implementation LMServerResponse

- (NSString *)description {
    return [NSString stringWithFormat:@"Status: %@; Data: %@", self.statusCode, self.data];
}

@end
