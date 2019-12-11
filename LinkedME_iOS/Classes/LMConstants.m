//
//  LMConstants.m
//  iOS-Deep-Linking-SDK
//  Created on 6/10/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMConstants.h"
#import "LKMEConfig.h"
NSString * const LINKEDME_REQUEST_KEY_LKME_IDENTITY = @"identity_id";
NSString * const LINKEDME_BROWSER_IDENTITY_ID = @"browser_misc";
NSString * const LINKEDME_REQUEST_KEY_DEVELOPER_IDENTITY = @"identity";
NSString * const LINKEDME_REQUEST_KEY_ACTION = @"event";
NSString * const LINKEDME_REQUEST_KEY_BUCKET = @"bucket";
NSString * const LINKEDME_REQUEST_KEY_AMOUNT = @"amount";
NSString * const LINKEDME_REQUEST_KEY_LENGTH = @"length";
NSString * const LINKEDME_REQUEST_KEY_DIRECTION = @"direction";
NSString * const LINKEDME_REQUEST_KEY_STARTING_TRANSACTION_ID = @"begin_after_id";
NSString * const LINKEDME_REQUEST_KEY_REFERRAL_USAGE_TYPE = @"calculation_type";
NSString * const LINKEDME_REQUEST_KEY_REFERRAL_REWARD_LOCATION = @"location";
NSString * const LINKEDME_REQUEST_KEY_REFERRAL_TYPE = @"type";
NSString * const LINKEDME_REQUEST_KEY_REFERRAL_CREATION_SOURCE = @"creation_source";
NSString * const LINKEDME_REQUEST_KEY_REFERRAL_PREFIX = @"prefix";
NSString * const LINKEDME_REQUEST_KEY_REFERRAL_EXPIRATION = @"expiration";
NSString * const LINKEDME_REQUEST_KEY_REFERRAL_CODE = @"referral_code";

NSString * const LINKEDME_REQUEST_KEY_URL_DATA = @"data";
NSString * const LINKEDME_REQUEST_KEY_APP_LIST = @"apps_data";
NSString * const LINKEDME_REQUEST_KEY_HARDWARE_ID = @"hardware_id";
NSString * const LINKEDME_REQUEST_KEY_IS_HARDWARE_ID_REAL = @"is_hardware_id_real";

NSString * const LINKEDME_REQUEST_KEY_DEBUG = @"debug";

NSString * const LINKEDME_REQUEST_KEY_URI_SCHEME = @"uri_scheme";

NSString * const LINKEDME_REQUEST_KEY_LINK_IDENTIFIER = @"link_identifier";

NSString * const LINKEDME_REQUEST_KEY_MODEL = @"model";

NSString * const LINKEDME_REQUEST_KEY_DEVICE_NAME = @"device_name";
NSString * const LINKEDME_REQUEST_KEY_IS_SIMULATOR = @"is_simulator";
NSString * const LINKEDME_REQUEST_KEY_LOG = @"log";


NSString * const LINKEDME_REQUEST_ENDPOINT_SET_IDENTITY = @"profile";
NSString * const LINKEDME_REQUEST_ENDPOINT_LOGOUT = @"logout";
NSString * const LINKEDME_REQUEST_ENDPOINT_USER_COMPLETED_ACTION = @"event";
NSString * const LINKEDME_REQUEST_ENDPOINT_LOAD_ACTIONS = @"referrals";
NSString * const LINKEDME_REQUEST_ENDPOINT_LOAD_REWARDS = @"credits";
NSString * const LINKEDME_REQUEST_ENDPOINT_REDEEM_REWARDS = @"redeem";
NSString * const LINKEDME_REQUEST_ENDPOINT_CREDIT_HISTORY = @"credithistory";
NSString * const LINKEDME_REQUEST_ENDPOINT_GET_PROMO_CODE = @"promo-code";
NSString * const LINKEDME_REQUEST_ENDPOINT_GET_REFERRAL_CODE = @"referralcode";
NSString * const LINKEDME_REQUEST_ENDPOINT_VALIDATE_PROMO_CODE = @"promo-code";
NSString * const LINKEDME_REQUEST_ENDPOINT_VALIDATE_REFERRAL_CODE = @"referralcode";
NSString * const LINKEDME_REQUEST_ENDPOINT_APPLY_PROMO_CODE = @"apply-promo-code";
NSString * const LINKEDME_REQUEST_ENDPOINT_APPLY_REFERRAL_CODE = @"applycode";
NSString * const LINKEDME_REQUEST_ENDPOINT_GET_SHORT_URL = @"url";
NSString * const LINKEDME_REQUEST_ENDPOINT_CLOSE = @"close";
NSString * const LINKEDME_REQUEST_ENDPOINT_GET_APP_LIST = @"applist";
NSString * const LINKEDME_REQUEST_ENDPOINT_UPDATE_APP_LIST = @"applist";
NSString * const LINKEDME_REQUEST_ENDPOINT_OPEN = @"open";
NSString * const LINKEDME_REQUEST_ENDPOINT_BUTTON = @"btn/ride/init";
NSString * const LINKEDME_REQUEST_ENDPOINT_INSTALL = @"install";
NSString * const LINKEDME_REQUEST_ENDPOINT_CONNECT_DEBUG = @"debug/connect";
NSString * const LINKEDME_REQUEST_ENDPOINT_DISCONNECT_DEBUG = @"debug/disconnect";
NSString * const LINKEDME_REQUEST_ENDPOINT_LOG = @"debug/log";
NSString * const LINKEDME_REQUEST_ENDPOINT_REGISTER_VIEW = @"register-view";
NSString * const LINKEDME_RESPONSE_KEY_INSTALL_PARAMS = @"referring_data";
NSString * const LINKEDME_RESPONSE_KEY_ACTION_COUNT_TOTAL = @"total";
NSString * const LINKEDME_RESPONSE_KEY_ACTION_COUNT_UNIQUE = @"unique";
NSString * const LINKEDME_RESPONSE_KEY_REFERREE = @"referree";
NSString * const LINKEDME_RESPONSE_KEY_REFERRAL_CODE = @"referral_code";
NSString * const LINKEDME_RESPONSE_KEY_PROMO_CODE = @"promo_code";
NSString * const LINKEDME_RESPONSE_KEY_URL = @"url";
NSString * const LINKEDME_RESPONSE_KEY_SPOTLIGHT_IDENTIFIER = @"spotlight_identifier";
NSString * const LINKEDME_RESPONSE_KEY_POTENTIAL_APPS = @"potential_apps";

NSString * const LINKEDME_RESPONSE_KEY_CLICKED_LKME_LINK = @"+clicked_linkedme_link";


NSString * const LINKEDME_SPOTLIGHT_PREFIX = @"cc.lkme";
NSString * const LINKEDME_LINK_DATA_KEY_OG_TITLE = @"$og_title";
NSString * const LINKEDME_LINK_DATA_KEY_OG_DESCRIPTION = @"$og_description";
NSString * const LINKEDME_LINK_DATA_KEY_OG_IMAGE_URL = @"$og_image_url";
NSString * const LINKEDME_LINK_DATA_SPOTLIGHTIDENTIFIER = @"$og_spotlightIderfier";
NSString * const LINKEDME_LINK_DATA_KEY_TITLE = @"+spotlight_title";
NSString * const LINKEDME_LINK_DATA_KEY_DESCRIPTION = @"+spotlight_description";
NSString * const LINKEDME_LINK_DATA_KEY_PUBLICLY_INDEXABLE = @"$publicly_indexable";
NSString * const LINKEDME_LINK_DATA_KEY_TYPE = @"+spotlight_type";
NSString * const LINKEDME_LINK_DATA_KEY_THUMBNAIL_URL = @"+spotlight_thumbnail_url";
NSString * const LINKEDME_LINK_DATA_KEY_KEYWORDS = @"$keywords";
NSString * const LINKEDME_LINK_DATA_KEY_CANONICAL_IDENTIFIER = @"$canonical_identifier";
NSString * const LINKEDME_LINK_DATA_KEY_CANONICAL_URL = @"$canonical_url";
NSString * const LINKEDME_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE = @"$exp_date";
NSString * const LINKEDME_LINK_DATA_KEY_CONTENT_TYPE = @"$content_type";
NSString * const LINKEDME_LINK_DATA_KEY_EMAIL_SUBJECT = @"$email_subject";





#pragma mark --修改

NSString * const LINKEDME_REQUEST_KEY_DEVICE_LINKEDME_KEY = @"linkedme_key";
NSString * const LINKEDME_REQUEST_KEY_DEVICE_FINGERPRINT_ID = @"device_fingerprint_id";
NSString * const LINKEDME_REQUEST_KEY_BUNDLE_ID = @"ios_bundle_id";
NSString * const LINKEDME_REQUEST_KEY_DEVICE_ID=@"device_id";
NSString * const LINKEDME_REQUEST_KEY_DEVICE_TYPE=@"device_type";
NSString * const LINKEDME_REQUEST_KEY_DEVICE_BRAND=@"device_brand";
NSString * const LINKEDME_REQUEST_KEY_DEVICE_MODEL=@"device_model";
NSString * const LINKEDME_REQUEST_KEY_HAS_BLUETOOTH=@"has_bluetooth";
NSString * const LINKEDME_REQUEST_KEY_HAS_NFC=@"has_nfc";
NSString * const LINKEDME_REQUEST_KEY_HAS_SIM=@"has_sim";
NSString * const LINKEDME_REQUEST_KEY_OS=@"os";
NSString * const LINKEDME_REQUEST_KEY_OS_VERSION=@"os_version";
NSString * const LINKEDME_REQUEST_KEY_OS_IDFA=@"idfa";
NSString * const LINKEDME_REQUEST_KEY_OS_IDFV=@"idfv";
NSString * const LINKEDME_REQUEST_KEY_OS_TIMESTAMP=@"timestamp";
NSString * const LKME_REQUEST_KEY_SCREEN_DPI=@"screen_dpi";
NSString * const LINKEDME_REQUEST_KEY_SCREEN_HEIGHT=@"screen_height";
NSString * const LINKEDME_REQUEST_KEY_SCREEN_WIDTH=@"screen_width";
NSString * const LINKEDME_REQUEST_KEY_IS_WIFT=@"is_wifi";
NSString * const LINKEDME_REQUEST_KEY_IS_REFERRABLE=@"is_referrable";
NSString * const LINKEDME_REQUEST_KEY_IS_DEBUG=@"is_debug";
NSString * const LINKEDME_REQUEST_KEY_CARRIER = @"carrier";
NSString * const LINKEDME_REQUEST_KEY_APP_VERSION = @"app_version";
NSString * const LINKEDME_REQUEST_KEY_UNIVERSAL_LINK_URL = @"universal_link_url";
NSString * const LINKEDME_REQUEST_KEY_UPDATE = @"sdk_update";
NSString * const LINKEDME_REQUEST_KEY_AD_TRACKING_ENABLED = @"ad_tracking_enabled";
NSString * const LINKEDME_REQUEST_KEY_TEAM_ID = @"ios_team_id";
NSString * const LINKEDME_REQUEST_KEY_SPOTLIGHT_IDENTIFIER = @"spotlight_identifier";
NSString * const LINKEDME_REQUEST_KEY_SESSION_ID = @"session_id";

NSString * const LINKEDME_IS_REFERABLE = @"is_referable";



NSString * const LINKEDME_RESPONSE_KEY_DEVELOPER_IDENTITY = @"identity";
NSString * const LINKEDME_RESPONSE_KEY_DEVICE_FINGERPRINT_ID = @"device_fingerprint_id";
NSString * const LINKEDME_RESPONSE_KEY_USER_URL = @"link";
NSString * const LINKEDME_RESPONSE_KEY_SESSION_ID = @"session_id";
NSString * const LINKEDME_RESPONSE_KEY_SESSION_DATA = @"params";
NSString * const LINKEDME_RESPONSE_KEY_CLICKED_LINKEDME_LINK = @"clicked_linkedme_link";
NSString * const LINKEDME_RESPONSE_KEY_IS_FIRST_SESSION=@"is_first_session";
NSString * const LKME_RESPONSE_KEY_URL = @"url";
NSString * const LINKEDME_RESPONSE_KEY_IDENTITY_ID = @"identity_id";

NSString * const LINKEDME_REQUEST_KEY_URL_SOURCE = @"source";
NSString * const LINKEDME_REQUEST_KEY_URL_TAGS = @"tags";
NSString * const LINKEDME_REQUEST_KEY_URL_LINK_TYPE = @"type";
NSString * const LINKEDME_REQUEST_KEY_URL_ALIAS = @"alias";
NSString * const LINKEDME_REQUEST_KEY_URL_CHANNEL = @"channel";
NSString * const LINKEDME_REQUEST_KEY_URL_FEATURE = @"feature";
NSString * const LINKEDME_REQUEST_KEY_URL_STAGE = @"stage";
NSString * const LINKEDME_REQUEST_KEY_URL_DURATION = @"duration";
NSString * const LKME_REQUEST_KEY_URL_DATA = @"params";
NSString * const LINKEDME_REQUEST_KEY_URL_IGNORE_UA_STRING = @"ignore_ua_string";
NSString * const LINKEDME_REQUEST_KEY_URL_METADATA = @"metadata";



NSString * const LINKEDME_LINK_DATA_KEY_METADATA = @"$metadata";
NSString * const LINKEDME_LINK_DATA_KEY_CONTROL = @"$control";


#pragma mark createBtnParamters

//NSString * const LINKEDME_REQUEST_KEY_BTN_ID = @"btn_id";

NSString * const LINKEDME_REQUEST_KEY_BTN_ID = @"btn_id";
NSString * const LINKEDME_REQUEST_KEY_PICKUP_LAT = @"pickup_lat";
NSString * const LINKEDME_REQUEST_KEY_PICKUP_LNG = @"pickup_lng";
NSString * const LINKEDME_REQUEST_KEY_PICKUP_LABEL = @"pickup_label";
NSString * const LINKEDME_REQUEST_KEY_DROPOFF_LAT = @"dropoff_lat";
NSString * const LINKEDME_REQUEST_KEY_DROPOFF_LNG = @"dropoff_lng";
NSString * const LINKEDME_REQUEST_KEY_DROPOFF_LABEL = @"dropoff_label";
NSString * const LINKEDME_REQUEST_KEY_SDK_VERSION = @"sdk_version";

NSString * const PARAMS_ANDROID_LINK = @"$android_deeplink_path";
NSString * const PARAMS_IOS_LINK = @"$ios_deeplink_key";
