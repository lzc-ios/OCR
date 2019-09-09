//
//  LFEncryption.h
//  BankCardScan
//
//  Created by linkface on 2018/9/10.
//  Copyright © 2018年 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFEncryption : NSObject

//md5字符串加密
+ (NSString *)md5String:(NSString *)sourceString;

/**
 md5加密

 @param str 要加密字符串
 @return 加密后的MD5值32位小写
 */
+ (NSString *)MD5ForLower32Bate:(NSString *)str;

@end
