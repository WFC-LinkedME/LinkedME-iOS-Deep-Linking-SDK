//
//  LMMeBaseEntity.h
//  iOS-Deep-Linking-SDK
//
//  Created on 16/4/13.
//  Copyright © 2016年 Bindx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMBaseEntity : NSObject

typedef void (^CompletionHandler) (BOOL);

typedef void (^innerCallBack) (LMBaseEntity *);

@property (nonatomic,strong) NSString * schemeUrl;
@property (nonatomic,strong) NSString * buttonIcon;
@property (nonatomic,copy)   NSDictionary *btn_msgDic;
@end
