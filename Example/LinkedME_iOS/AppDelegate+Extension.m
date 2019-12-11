//
//  AppDelegate+didfinish.m
//  LinkedME_iOS
//
//  Created by Admin on 31/03/2017.
//  Copyright © 2017 Bindx. All rights reserved.
//

#import "AppDelegate+Extension.h"
#import <objc/runtime.h>

//不用导入项目中

@implementation AppDelegate(Extension)

+ (void)load{
    swizzleMethod([self class], @selector(application:continueUserActivity:restorationHandler:), @selector(swizzled_application:continueUserActivity:restorationHandler:));
}

- (BOOL)swizzled_application:(UIApplication*)application continueUserActivity:(NSUserActivity*)userActivity restorationHandler:(void (^)(NSArray*))restorationHandler{
    
    NSMutableString *webPageUrl = [[NSMutableString alloc]initWithString:[userActivity.webpageURL absoluteString]];
    
    if ([webPageUrl rangeOfString:@"linkedmeurl"].location != NSNotFound) {
        
        NSString *pageStart = @"linkedmeurl";
        
        long int startOffset=[webPageUrl rangeOfString:pageStart].location+12;
        
        long int endOffset = webPageUrl.length;
        
        //截取substring
        NSString *linkedmeUrl = [webPageUrl substringWithRange:NSMakeRange(startOffset, endOffset-startOffset)];
        
        [userActivity setWebpageURL:[NSURL URLWithString:linkedmeUrl]];
    }
    [self swizzled_application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    
    return YES;
}

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector){
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end
