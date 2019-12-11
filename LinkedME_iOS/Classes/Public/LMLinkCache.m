//
//  LMLinkCache.m
//  iOS-Deep-Linking-SDK
//
//  Created on 1/23/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMLinkCache.h"

@interface LMLinkCache ()

@property (nonatomic, strong) NSMutableDictionary *cache;

@end

@implementation LMLinkCache

- (id)init {
    if (self = [super init]) {
        self.cache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)setObject:(NSString *)anObject forKey:(LMLinkData *)aKey{
    self.cache[@([aKey hash])] = anObject;
}

-(NSString *)objectForKey:(LMLinkData *)aKey{
    return self.cache[@([aKey hash])];
}

@end
