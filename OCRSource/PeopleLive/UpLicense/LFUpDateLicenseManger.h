//
//  LFUpLicenseManger.h
//  BankCardScan
//
//  Created by linkface on 2018/9/7.
//  Copyright © 2018年 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFUpDateLicenseManger : NSObject

/*!
 @brief  传入license文件有效路径和更新缓存路径
 @result licensePath是否有效
 @param  licensePath    license工程文件路径
 @param  cachePath   license缓存路径
 */
+ (BOOL)loadLicensePath:(NSString *)licensePath cachePath:(NSString *)cachePath;

@end
