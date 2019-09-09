//
//  LFEncryption.m
//  BankCardScan
//
//  Created by linkface on 2018/9/10.
//  Copyright © 2018年 SenseTime. All rights reserved.
//

#import "LFEncryption.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation LFEncryption

+ (NSString *)md5String:(NSString *)sourceString{
    if (!sourceString){
        return nil;
    }
    
    const char *cString = sourceString.UTF8String;
    unsigned char result[CC_MD5_BLOCK_LONG];
    CC_MD5(cString, (CC_LONG)strlen(cString), result);

    NSMutableString *digest = [NSMutableString stringWithCapacity:CC_MD5_BLOCK_LONG];
    //遍历所有的result数组，取出所有的字符来拼接
    for (int i = 0;i < CC_MD5_BLOCK_LONG; i++) {
        [digest  appendFormat:@"%02x",result[i]];
    }
    return digest;
}

+ (NSString *)MD5ForLower32Bate:(NSString *)str{
    
    //要进行UTF8的转码
    const char* input = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(input, (CC_LONG)strlen(input), result);
    
    NSMutableString *digest = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [digest appendFormat:@"%02x", result[i]];
    }
    return digest;
}

@end
