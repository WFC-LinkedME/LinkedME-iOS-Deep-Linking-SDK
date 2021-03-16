//
//  LMEncodingUtils.h
//  iOS-Deep-Linking-SDK
//
//  Created on 3/31/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import <Foundation/Foundation.h>

//Encoding

@interface LMEncodingUtils : NSObject

#pragma mark WireFormat

extern NSDate*   LMDateFromWireFormat(id object);
extern NSNumber* LMWireFormatFromDate(NSDate *date);
extern NSNumber* LMWireFormatFromBool(BOOL b);

extern NSString* LMStringFromWireFormat(id object);
extern NSString* LMWireFormatFromString(NSString *string);


+ (NSString *)base64EncodeStringToString:(NSString *)strData;
+ (NSString *)base64DecodeStringToString:(NSString *)strData;
+ (NSString *)base64EncodeData:(NSData *)objData;

+ (NSString *)md5Encode:(NSString *)input;

+ (NSString *)encodeArrayToJsonString:(NSArray *)dictionary;
+ (NSString *)encodeDictionaryToJsonString:(NSDictionary *)dictionary;
+ (NSData *)encodeDictionaryToJsonData:(NSDictionary *)dictionary;

+ (NSDictionary *)decodeJsonDataToDictionary:(NSData *)jsonData;
+ (NSDictionary *)decodeJsonStringToDictionary:(NSString *)jsonString;
+ (NSDictionary *)decodeQueryStringToDictionary:(NSString *)queryString;
+ (NSString *)encodeDictionaryToQueryString:(NSDictionary *)dictionary;
+ (NSString *)hmacSha1:(NSString *)key text:(NSString *)text;
+ (NSString *)encryptAES:(NSString *)content key:(NSString *)key;
+ (NSString *)decryptAES:(NSString *)content key:(NSString *)key;
+ (NSString *)urlEncodedString:(NSString *)string;

/**
 *  传入NSArray生成Sign签名
 *
 *  @param params array
 *
 *  @return sign
 */
+ (NSString *)sign:(NSArray *)params;

@end
