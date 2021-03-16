//
//  RHKeyChain.h
//  Pods
//
//  Created by Bindx on 7/5/16.
//
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface LMKeychain : NSObject

+ (void)save:(NSString *)service data:(id)data;

+ (id)load:(NSString *)service;
+ (void)delete:(NSString *)service;
+ (id) retrieveValueForService:(NSString*)service
                           key:(NSString*)key
                         error:(NSError**)error;

+ (NSError*) storeValue:(id)value
             forService:(NSString*)service
                    key:(NSString*)key
       cloudAccessGroup:(NSString*)accessGroup;
+ (NSString*_Nullable) securityAccessGroup;

@end
