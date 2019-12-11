//
//  LMServerRequest.m
//  iOS-Deep-Linking-SDK
//
//  Created on 5/22/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMServerRequest.h"

@implementation LMServerRequest

- (void)makeRequest:(LMServerInterface *)serverInterface key:(NSString *)key callback:(LMServerCallback)callback {
    NSLog(@"[Improper LKMEServerRequest] LKMEServerRequest subclasses must implement makeRequest:key:callback:");
}

- (void)processResponse:(LMServerResponse *)response error:(NSError *)error {
    NSLog(@"[Improper LKMEServerRequest] LKMEServerRequest subclasses must implement processResponse:error:");
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return self = [super init];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    // Nothing going on here
}

@end
