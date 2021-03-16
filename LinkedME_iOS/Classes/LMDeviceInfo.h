//
//  LMDeviceInfo.h
//  iOS-Deep-Linking-SDK
//
//  Created on 16-3-22.
//  Copyright © 2016年 Bindx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMDeviceInfo : NSObject

//设备信息
@property (strong,nonatomic)NSString * deviceId;
@property (assign,nonatomic)NSUInteger deviceType;

+ (NSString *)getModel;

@end
