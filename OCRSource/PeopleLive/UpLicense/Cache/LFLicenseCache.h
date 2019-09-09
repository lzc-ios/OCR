//
//  LFLicenseCache.h
//  BankCardScan
//
//  Created by 宋立军 on 2018/9/11.
//  Copyright © 2018年 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFLicenseCache : NSObject

+ (BOOL)addLicCacheWithLicContent:(NSString *)licContent licCachePath:(NSString *)licCachePath;

@end
