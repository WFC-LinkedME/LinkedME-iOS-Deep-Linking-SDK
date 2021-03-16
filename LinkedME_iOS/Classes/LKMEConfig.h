//
//  LMConfig.h
//  iOS-Deep-Linking-SDK
//
//  Created on 10/6/14.
//  Copyright (c) 2014 Bindx. All rights reserved.
//

#ifndef LinkedME_SDK_Config_h
#define LinkedME_SDK_Config_h

#define  KOnlineSecretKey       //线上环境，线上环®境优先级最高

#ifdef KOnlineSecretKey

// 正式
#define LKME_API_BASE_URL(HTTPS)   HTTPS?@"https://lkme.cc":@"http://lkme.cc"

//#define LKME_API_BASE_URL

#define LKME_API_VERSION         @"i"

#else

// 测试
#define LKME_API_BASE_URL        @"http://101.201.78.89:8088"
#define LKME_API_VERSION         @"t"

#endif


#define LKME_KEY(LIVE) LIVE?[NSBundle mainBundle].infoDictionary[@"linkedme_key"][@"live"]:\
[NSBundle mainBundle].infoDictionary[@"linkedme_key"][@"live"]

#define SDK_VERSION             @"1.5.5.1"

#define LKME_PROD_ENV

#ifdef LKME_PROD_ENV

#endif

#ifdef LKME_STAGE_ENV

#define LKME_API_BASE_URL            @"http://10.1.24.31:8080/"
#endif

#define LKME_LINK_URL               @"http://10.1.24.31:8080/"


#ifdef  LKME_DEV_ENV
#define LKME_API_BASE_URL            @"http://localhost:3001"
#endif


#define LKME_API_PREFIX_SDK         @"sdk"
#define LKME_API_PREFIX_MONITOR     @"track"
#define LKME_API_PREFIX_GAME        @"game"
#define LKME_API_PREFIX_UBER        @"uber"
#define UBER_SERIVER_TOKEN          @"MKNqADasDys70b6R9HBEW-51fM59sEM3r8pWHibB"


#endif
