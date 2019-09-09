//
//  LFLoadLicense.h
//  BankCardScan
//
//  Created by linkface on 2018/9/7.
//  Copyright © 2018年 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFLoadLicense : NSObject

/**
 下载licenseJson

 @param Url 下载路径
 */
+ (void)downLoadLicenseJsonUrl:(NSString *_Nullable)Url completeBlock:(void(^_Nullable)(NSDictionary * _Nullable licenseJson,NSError * _Nullable error))completeBlcok;

/**
 下载license

 @param licenseUrl 下载地址
 @param completeBlcok 下载license字符串
 */
+ (void)downLoadLicenseUrl:(NSString *_Nonnull)licenseUrl completeBlock:(void(^_Nullable)(NSString * _Nullable license,NSError * _Nullable error))completeBlcok;

@end
