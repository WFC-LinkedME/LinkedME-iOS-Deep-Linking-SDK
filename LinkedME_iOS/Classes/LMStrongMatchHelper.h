//
//  LMStrongMatchHelper.h
//  iOS-Deep-Linking-SDK
//
//  Created on 8/26/15.
//  Copyright © 2015 Bindx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LMStrongMatchHelper : NSObject

+ (LMStrongMatchHelper *)strongMatchHelper;
- (void)createStrongMatchWithLinkedMEKey:(NSString *)linkedMEKey;
- (BOOL)shouldDelayInstallRequest;

@end
