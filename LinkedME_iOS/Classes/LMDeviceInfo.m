//
//  LMDeviceInfo.m
//  iOS-Deep-Linking-SDK
//
//  Created on 16-3-22.
//  Copyright © 2016年 Bindx. All rights reserved.
//

#import "LMDeviceInfo.h"
#include <sys/sysctl.h>


@implementation LMDeviceInfo

+ (NSString *)getModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.machine", model, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    free(model);
    return deviceModel;
}

@end
