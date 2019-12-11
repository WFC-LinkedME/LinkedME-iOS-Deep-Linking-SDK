//
//  DetailViewController.m
//  LinkedME_DEMO
//
//  Created by LinkedME04 on 6/7/16.
//  Copyright © 2016 Bindx. All rights reserved.
//

#import "DetailViewController.h"
#import "LinkedME.h"
#import "LMUniversalObject.h"
#import "LMLinkProperties.h"
#import <Social/Social.h>


//static NSString * const H5_TEST_URL = @"http://192.168.10.101:8888/h5/summary?linkedme=";
static NSString * const H5_LIVE_URL = @"https://www.linkedme.cc/h5/summary?linkedme=";
static NSString * LINKEDME_SHORT_URL;

@interface DetailViewController ()

@property (strong, nonatomic) LMUniversalObject *linkedUniversalObject;

@end

@implementation DetailViewController{
    BOOL deepLinking;
    NSString *title;
    NSArray *arr;
    NSString * H5_LIVE_URL;
}

@synthesize deepLinkingCompletionDelegate;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initData];
    [self initMoreButton];
    [self addPara];
}

- (void)configureControlWithData:(NSDictionary *)data{
    _openUrl = [data objectForKey:@"tag"];
}

- (void)initData{
    NSString *Plist=[[NSBundle mainBundle] pathForResource:@"DefaultData" ofType:@"plist"];
    arr = [[NSArray alloc]initWithContentsOfFile:Plist];
    
    if (!_openUrl.length) {
        _openUrl = [NSString stringWithFormat:@"%@%@",arr[_page][@"url"],[LMPreferenceHelper preferenceHelper].linedMEKey];
    }
    [self loadString:_openUrl];
    title = arr[_page][@"key"];
}

//- (void)setPage:(NSUInteger)index{
//    _page = index;
//}

//初始化更多按钮
-(void)initMoreButton{
    UIButton *sharBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.width-50, 20, 40, 40)];
//    [sharBtn setImage:[UIImage imageNamed:@"more.png"] forState:UIControlStateNormal];
    [sharBtn setTitle:@"分享" forState:UIControlStateNormal];
    [sharBtn addTarget:self action:@selector(umShare) forControlEvents:UIControlEventTouchDown];
    UIBarButtonItem *rightBraBttonItem = [[UIBarButtonItem alloc]initWithCustomView:sharBtn];
    self.navigationItem.rightBarButtonItem = rightBraBttonItem;
}


//分享
- (void)umShare{
    
    NSString *title = @"LinkedME深度链接";

    UIImage *imageToSharee = [UIImage imageNamed:@"AppIcon.png"];
    
    NSURL *url = [NSURL URLWithString:LINKEDME_SHORT_URL];
    
    NSArray *activityItemss = @[title,imageToSharee,url];
       
    UIActivityViewController *activityVCC = [[UIActivityViewController alloc]initWithActivityItems:activityItemss applicationActivities:nil];
       
    [self presentViewController:activityVCC animated:TRUE completion:nil];
}


//创建短链
-(void)addPara{
    self.linkedUniversalObject = [[LMUniversalObject alloc] init];
    self.linkedUniversalObject.title = title;//标题
    
    LMLinkProperties *linkProperties = [[LMLinkProperties alloc] init];
    linkProperties.channel = @"";//渠道(微信,微博,QQ,等...)
    linkProperties.feature = @"Share";//特点
    linkProperties.tags=@[@"LinkedME",@"Demo"];//标签
    linkProperties.stage = @"Live";//阶段
    [linkProperties addControlParam:@"ViewID" withValue:arr[_page][@"url"]];//页面唯一标识
    [linkProperties addControlParam:@"LinkedME" withValue:@"Demo"];//Demo标识


    //开始请求短链
    [self.linkedUniversalObject getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString *url, NSError *err) {
        if (url) {
            NSLog(@"[LinkedME Info] SDK creates the url is:%@", url);
            //拼接连接
            [self->H5_LIVE_URL stringByAppendingString:self->arr[self->_page][@"form"]];
            [self->H5_LIVE_URL stringByAppendingString:@"?linkedme="];
            
            self->H5_LIVE_URL = [NSString stringWithFormat:@"https://www.linkedme.cc/h5/%@?linkedme=",self->arr[self->_page][@"form"]];
            //前面是Html5页面,后面拼上深度链接https://xxxxx.xxx (html5 页面地址) ?linkedme=(深度链接)
            //https://www.linkedme.cc/h5/feature?linkedme=https://lkme.cc/AfC/mj9H87tk7
            LINKEDME_SHORT_URL = [self->H5_LIVE_URL stringByAppendingString:url];
        } else {
            LINKEDME_SHORT_URL = self->H5_LIVE_URL;
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadString:(NSString *)str{
    NSURL *url = [NSURL URLWithString:str];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

