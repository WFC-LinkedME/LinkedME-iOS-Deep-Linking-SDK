//
//  DetailViewController.h
//  LinkedME_DEMO
//
//  Created by LinkedME04 on 6/7/16.
//  Copyright © 2016 Bindx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMDeepLinkingController.h"

@interface DetailViewController : UIViewController<LMDeepLinkingController>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) NSString *openUrl;

@property (assign, nonatomic) NSInteger page;

@property (assign, nonatomic) BOOL deepLinking;

@end
