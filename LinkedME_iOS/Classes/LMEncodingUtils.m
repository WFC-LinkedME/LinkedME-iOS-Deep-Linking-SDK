//
//  LMEncodingUtils.m
//  iOS-Deep-Linking-SDK
//
//  Created on 3/31/15.
//  Copyright (c) 2015 Bindx. All rights reserved.
//

#import "LMEncodingUtils.h"
#import "LMPreferenceHelper.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>


@implementation LMEncodingUtils

NSString *const lmkInitVector = @"16-Bytes--String";
size_t const lmkKeySize = kCCKeySizeAES128;


NSDate* LMDateFromWireFormat(id object) {
    NSDate *date = nil;
    if ([object respondsToSelector:@selector(doubleValue)]) {
        NSTimeInterval t = [object doubleValue];
        date = [NSDate dateWithTimeIntervalSince1970:t/1000.0];
    }
    return date;
}

NSNumber* LMWireFormatFromDate(NSDate *date) {
    NSNumber *number = nil;
    NSTimeInterval t = [date timeIntervalSince1970];
    if (date && t != 0.0 ) {
        number = [NSNumber numberWithLongLong:(long long)(t*1000.0)];
    }
    return number;
}

NSNumber* LMWireFormatFromBool(BOOL b) {
    return (b) ? (__bridge NSNumber*) kCFBooleanTrue : nil;
}

NSString* LMStringFromWireFormat(id object) {
    if ([object isKindOfClass:NSString.class])
        return object;
    else
    if ([object respondsToSelector:@selector(stringValue)])
        return [object stringValue];
    else
    if ([object respondsToSelector:@selector(description)])
        return [object description];
    return nil;
}

NSString* LMWireFormatFromString(NSString *string) {
    return string;
}

#pragma mark - Base 64 encoding

// BASE 64 encoding brought to you by http://ios-dev-blog.com/base64-encodingdecoding/

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const short _base64DecodingTable[256] = {
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
    -2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
    -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};

+ (NSString *)base64EncodeStringToString:(NSString *)strData {
    return [self base64EncodeData:[strData dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSString *)base64DecodeStringToString:(NSString *)strData {
    NSData* data =[LMEncodingUtils base64DecodeString:strData];
    if (data == nil) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString *)hmacSha1:(NSString *)key text:(NSString *)text{
    const char *cKey  = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [text cStringUsingEncoding:NSUTF8StringEncoding];
    char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:CC_SHA1_DIGEST_LENGTH];
    NSString *hash = [HMAC base64Encoding];//base64Encoding函数在NSData+Base64中定义（NSData+Base64网上有很多资源）
    return hash;
}

+ (NSString *)encryptAES:(NSString *)content key:(NSString *)key {
    
    NSData *contentData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger dataLength = contentData.length;
    
    // 为结束符'\\0' +1
    char keyPtr[lmkKeySize + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    // 密文长度 <= 明文长度 + BlockSize
    size_t encryptSize = dataLength + kCCBlockSizeAES128;
    void *encryptedBytes = malloc(encryptSize);
    size_t actualOutSize = 0;
    
    NSData *initVector = [lmkInitVector dataUsingEncoding:NSUTF8StringEncoding];
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,  // 系统默认使用 CBC，然后指明使用 PKCS7Padding
                                          keyPtr,
                                          lmkKeySize,
                                          initVector.bytes,
                                          contentData.bytes,
                                          dataLength,
                                          encryptedBytes,
                                          encryptSize,
                                          &actualOutSize);
    
    if (cryptStatus == kCCSuccess) {
        // 对加密后的数据进行 base64 编码
        return [[NSData dataWithBytesNoCopy:encryptedBytes length:actualOutSize] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    }
    free(encryptedBytes);
    return nil;
}

+ (NSString *)decryptAES:(NSString *)content key:(NSString *)key {
    
    NSData *contentData = [[NSData alloc] initWithBase64EncodedString:content options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSUInteger dataLength = contentData.length;
    
    char keyPtr[lmkKeySize + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    size_t decryptSize = dataLength + kCCBlockSizeAES128;
    void *decryptedBytes = malloc(decryptSize);
    size_t actualOutSize = 0;
    
    NSData *initVector = [lmkInitVector dataUsingEncoding:NSUTF8StringEncoding];
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          lmkKeySize,
                                          initVector.bytes,
                                          contentData.bytes,
                                          dataLength,
                                          decryptedBytes,
                                          decryptSize,
                                          &actualOutSize);
    
    if (cryptStatus == kCCSuccess) {
        return [[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:decryptedBytes length:actualOutSize] encoding:NSUTF8StringEncoding];
    }
    free(decryptedBytes);
    return nil;
}

+ (NSString *)base64EncodeData:(NSData *)data {
    const char * input = [data bytes];
    unsigned long inputLength = [data length];
    unsigned long modulo = inputLength % 3;
    unsigned long outputLength = (inputLength / 3) * 4 + (modulo ? 4 : 0);
    unsigned long j = 0;
    
    // Do not forget about trailing zero
    unsigned char *output = malloc(outputLength + 1);
    output[outputLength] = 0;
    
    // Here are no checks inside the loop, so it works much faster than other implementations
    for (unsigned long i = 0; i < inputLength; i += 3) {
        output[j++] = _base64EncodingTable[ (input[i] & 0xFC) >> 2 ];
        output[j++] = _base64EncodingTable[ ((input[i] & 0x03) << 4) | ((input[i + 1] & 0xF0) >> 4) ];
        output[j++] = _base64EncodingTable[ ((input[i + 1] & 0x0F)) << 2 | ((input[i + 2] & 0xC0) >> 6) ];
        output[j++] = _base64EncodingTable[ (input[i + 2] & 0x3F) ];
    }
    
    // Padding in the end of encoded string directly depends of modulo
    if (modulo > 0) {
        output[outputLength - 1] = '=';
        if (modulo == 1) {
            output[outputLength - 2] = '=';
        }
    }
    
    NSString *s = [NSString stringWithUTF8String:(const char *)output];
    free(output);
    return s;
}

+ (NSData *)base64DecodeString:(NSString *)strBase64 {
    const char * objPointer = [strBase64 cStringUsingEncoding:NSASCIIStringEncoding];
    if (objPointer == NULL) {
        return nil;
    }
    long intLength = strlen(objPointer);
    int intCurrent;
    int i = 0, j = 0, k;
    
    char * objResult;
    objResult = calloc(intLength, sizeof(char));
    
    // Run through the whole string, converting as we go
    while ( ((intCurrent = *objPointer++) != '\0') && (intLength-- > 0) ) {
        if (intCurrent == '=') {
            if (*objPointer != '=' && ((i % 4) == 1)) {// || (intLength > 0)) {
                // the padding character is invalid at this point -- so this entire string is invalid
                free(objResult);
                return nil;
            }
            continue;
        }
        
        intCurrent = _base64DecodingTable[intCurrent];
        if (intCurrent == -1) {
            // we're at a whitespace -- simply skip over
            continue;
        } else if (intCurrent == -2) {
            // we're at an invalid character
            free(objResult);
            return nil;
        }
        
        switch (i % 4) {
            case 0:
                objResult[j] = intCurrent << 2;
                break;
                
            case 1:
                objResult[j++] |= intCurrent >> 4;
                objResult[j] = (intCurrent & 0x0f) << 4;
                break;
                
            case 2:
                objResult[j++] |= intCurrent >>2;
                objResult[j] = (intCurrent & 0x03) << 6;
                break;
                
            case 3:
                objResult[j++] |= intCurrent;
                break;
        }
        i++;
    }
    
    // mop things up if we ended on a boundary
    k = j;
    if (intCurrent == '=') {
        switch (i % 4) {
            case 1:
                // Invalid state
                free(objResult);
                return nil;
                
            case 2:
                k++;
                // flow through
            case 3:
                objResult[k] = 0;
        }
    }
    
    // Cleanup and setup the return NSData
    NSData * objData = [[NSData alloc] initWithBytes:objResult length:j] ;
    free(objResult);
    return objData;
}


#pragma mark - MD5 methods

+ (NSString *)md5Encode:(NSString *)input {
    if (!input) {
        return @"";
    }

    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    return  output;
}


#pragma mark - Param Encoding methods

+ (NSString *)iso8601StringFromDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]]; // POSIX to avoid weird issues
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    });
    
    return [dateFormatter stringFromDate:date];
}

+ (NSString *)sanitizedStringFromString:(NSString *)dirtyString {
    NSString *cleanString = [[[[dirtyString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]
                                            stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]
                                            stringByReplacingOccurrencesOfString:@"’" withString:@"'"]
                                            stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];

    return cleanString;
}

+ (NSData *)encodeDictionaryToJsonData:(NSDictionary *)dictionary {
    NSString *jsonString = [LMEncodingUtils encodeDictionaryToJsonString:dictionary];
    NSUInteger length = [jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    return [NSData dataWithBytes:[jsonString UTF8String] length:length];
}

+ (NSString *)encodeDictionaryToJsonString:(NSDictionary *)dictionary {
    NSMutableString *encodedDictionary = [[NSMutableString alloc] initWithString:@"{"];
    for (NSString *key in dictionary) {
        NSString *value = nil;
        BOOL string = YES;
        
        id obj = dictionary[key];
        if ([obj isKindOfClass:[NSString class]]) {
            value = [LMEncodingUtils sanitizedStringFromString:obj];
        }
        else if ([obj isKindOfClass:[NSURL class]]) {
            value = [obj absoluteString];
        }
        else if ([obj isKindOfClass:[NSDate class]]) {
            value = [LMEncodingUtils iso8601StringFromDate:obj];
        }
        else if ([obj isKindOfClass:[NSArray class]]) {
            value = [LMEncodingUtils encodeArrayToJsonString:obj];
            string = NO;
        }
        else if ([obj isKindOfClass:[NSDictionary class]]) {
            value = [LMEncodingUtils encodeDictionaryToJsonString:obj];
            string = NO;
        }
        else if ([obj isKindOfClass:[NSNumber class]]) {
            value = [obj stringValue];
            string = NO;
        }
        else if ([obj isKindOfClass:[NSNull class]]) {
            value = @"null";
            string = NO;
        }
        else {
            // If this type is not a known type, don't attempt to encode it.
            NSLog(@"Cannot encode value for key %@, type is in list of accepted types", key);
            continue;
        }
        
        [encodedDictionary appendFormat:@"\"%@\":", [LMEncodingUtils sanitizedStringFromString:key]];
        
        // If this is a "string" object, wrap it in quotes
        if (string) {
            [encodedDictionary appendFormat:@"\"%@\",", value];
        }
        // Otherwise, just add the raw value after the colon
        else {
            [encodedDictionary appendFormat:@"%@,", value];
        }
    }
    
    if (encodedDictionary.length > 1) {
        [encodedDictionary deleteCharactersInRange:NSMakeRange([encodedDictionary length] - 1, 1)];
    }

    [encodedDictionary appendString:@"}"];
    
    if ([[LMPreferenceHelper preferenceHelper] isDebug]) {
        NSLog(@"encoded dictionary : %@", encodedDictionary);
    }
    
    return encodedDictionary;
}

+ (NSString *)encodeArrayToJsonString:(NSArray *)array {
    // Empty array
    if (![array count]) {
        return @"[]";
    }

    NSMutableString *encodedArray = [[NSMutableString alloc] initWithString:@"["];
    for (id obj in array) {
        NSString *value = nil;
        BOOL string = YES;
        
        if ([obj isKindOfClass:[NSString class]]) {
            value = [LMEncodingUtils sanitizedStringFromString:obj];
        }
        else if ([obj isKindOfClass:[NSURL class]]) {
            value = [obj absoluteString];
        }
        else if ([obj isKindOfClass:[NSDate class]]) {
            value = [LMEncodingUtils iso8601StringFromDate:obj];
        }
        else if ([obj isKindOfClass:[NSArray class]]) {
            value = [LMEncodingUtils encodeArrayToJsonString:obj];
            string = NO;
        }
        else if ([obj isKindOfClass:[NSDictionary class]]) {
            value = [LMEncodingUtils encodeDictionaryToJsonString:obj];
            string = NO;
        }
        else if ([obj isKindOfClass:[NSNumber class]]) {
            value = [obj stringValue];
            string = NO;
        }
        else if ([obj isKindOfClass:[NSNull class]]) {
            value = @"null";
            string = NO;
        }
        else {
            // If this type is not a known type, don't attempt to encode it.
            NSLog(@"Cannot encode value %@, type is not in list of accepted types", obj);
            continue;
        }
        
        // If this is a "string" object, wrap it in quotes
        if (string) {
            [encodedArray appendFormat:@"\"%@\",", value];
        }
        // Otherwise, just add the raw value after the colon
        else {
            [encodedArray appendFormat:@"%@,", value];
        }
    }
    
    // Delete the trailing comma
    [encodedArray deleteCharactersInRange:NSMakeRange([encodedArray length] - 1, 1)];
    [encodedArray appendString:@"]"];
    
    if ([[LMPreferenceHelper preferenceHelper] isDebug]) {
        NSLog(@"encoded array : %@", encodedArray);
    }

    return encodedArray;
}

+ (NSString *)urlEncodedString:(NSString *)string {
    NSMutableCharacterSet *charSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [charSet removeCharactersInString:@"!*'\"();:@&=+$,/?%#[]% "];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:charSet];
}

+ (NSString *)encodeDictionaryToQueryString:(NSDictionary *)dictionary {
    NSMutableString *queryString = [[NSMutableString alloc] initWithString:@"?"];

    for (NSString *key in [dictionary allKeys]) {
        // No empty keys, please.
        if (key.length) {
            id obj = dictionary[key];
            NSString *value;
            
            if ([obj isKindOfClass:[NSString class]]) {
                value = [LMEncodingUtils urlEncodedString:obj];
            }
            else if ([obj isKindOfClass:[NSURL class]]) {
                value = [LMEncodingUtils urlEncodedString:[obj absoluteString]];
            }
            else if ([obj isKindOfClass:[NSDate class]]) {
                value = [LMEncodingUtils iso8601StringFromDate:obj];
            }
            else if ([obj isKindOfClass:[NSNumber class]]) {
                value = [obj stringValue];
            }
            else {
                // If this type is not a known type, don't attempt to encode it.
                NSLog(@"Cannot encode value %@, type is in not list of accepted types", obj);
                continue;
            }
            
            [queryString appendFormat:@"%@=%@&", [LMEncodingUtils urlEncodedString:key], value];
        }
    }

    // Delete last character (either trailing & or ? if no params present)
    [queryString deleteCharactersInRange:NSMakeRange(queryString.length - 1, 1)];
    
    return queryString;
}

#pragma mark - Param Decoding methods
+ (NSDictionary *)decodeJsonDataToDictionary:(NSData *)jsonData {
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return [LMEncodingUtils decodeJsonStringToDictionary:jsonString];
}

+ (NSDictionary *)decodeJsonStringToDictionary:(NSString *)jsonString {
    // Just a basic decode, easy enough
    NSData *tempData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!tempData) {
        return @{};
    }

    NSDictionary *plainDecodedDictionary = [NSJSONSerialization JSONObjectWithData:tempData options:NSJSONReadingMutableContainers error:nil];
    if (plainDecodedDictionary) {
        return plainDecodedDictionary;
    }

    // If the first decode failed, it could be because the data was encoded. Try decoding first.
    NSString *decodedVersion = [LMEncodingUtils base64DecodeStringToString:jsonString];
    tempData = [decodedVersion dataUsingEncoding:NSUTF8StringEncoding];
    if (!tempData) {
        return @{};
    }

    NSDictionary *base64DecodedDictionary = [NSJSONSerialization JSONObjectWithData:tempData options:NSJSONReadingMutableContainers error:nil];
    if (base64DecodedDictionary) {
        return base64DecodedDictionary;
    }

    // Apparently this data was not parsible into a dictionary, so we'll just return an empty one
    return @{};
}

+ (NSDictionary *)decodeQueryStringToDictionary:(NSString *)queryString {
    NSArray *pairs = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        if (kv.count > 1) { // If this key has a value (so, not foo&bar=...)
            NSString *key = kv[0];
            NSString *val;
            
            //Pre iOS 7, stringByReplacingPercentEscapesUsingEncoding was deprecated in iOS 9
            if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_7_0) {
                val = [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            } else { //iOS 7 and later
                val = [kv[1] stringByRemovingPercentEncoding]; // uses the default UTF-8 encoding, introduced in iOS 7
            }
            
            // Don't add empty items
            if (val.length) {
                params[key] = val;
            }
        }
    }

    return params;
}


+ (NSString *)sign:(NSArray *)params{
    NSMutableString *result = [NSMutableString new];
    for (int i = 0; i<params.count; i++) {
        if (i == 0) {
            [result appendFormat:@"%@:",params[i]];
        }else if(i == 1){
            [result appendFormat:@"%@",params[i]];
        }else{
            [result appendFormat:@"&%@",params[i]];
        }
    }
    return [LMEncodingUtils md5Encode:result];
}

@end
