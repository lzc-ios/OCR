//
//  LFLicenseCache.m
//  BankCardScan
//
//  Created by 宋立军 on 2018/9/11.
//  Copyright © 2018年 SenseTime. All rights reserved.
//

#import "LFLicenseCache.h"

static NSString * const LFNewCacheFile = @"LFNewCacheFile";

@implementation LFLicenseCache

+ (BOOL)addLicCacheWithLicContent:(NSString *)licContent licCachePath:(NSString *)licCachePath {
    
    if (![licContent isKindOfClass:[NSString class]]
        || ![licCachePath isKindOfClass:[NSString class]]
        || !licContent.length
        || !licCachePath.length)
    {
        return NO;
    }
    
    NSArray *pathArray = [licCachePath componentsSeparatedByString:@"/"];
    NSMutableArray *mPathArray = [NSMutableArray arrayWithArray:pathArray];
    [mPathArray insertObject:LFNewCacheFile atIndex:mPathArray.count - 1];
    NSString *newCachePath = [mPathArray componentsJoinedByString:@"/"];
    NSMutableArray *mNewPathFilrArray = [NSMutableArray arrayWithArray:mPathArray];
    [mNewPathFilrArray removeLastObject];
    NSString *newCachePathFile = [mNewPathFilrArray componentsJoinedByString:@"/"];

    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:newCachePathFile]) {
        [fm createDirectoryAtPath:newCachePathFile withIntermediateDirectories:YES attributes:nil error:nil];
    }

    // 是否缓存过
    BOOL oldLic = [fm fileExistsAtPath:licCachePath];
    if (oldLic){
        
        [fm copyItemAtPath:licCachePath toPath:newCachePath error:nil];
        [fm fileExistsAtPath:newCachePath];
    }
    
    NSData *data = [licContent dataUsingEncoding:NSUTF8StringEncoding];
    BOOL results = [fm createFileAtPath:licCachePath contents:data attributes:nil];

    if (!results && oldLic) [fm copyItemAtPath:newCachePath toPath:licCachePath error:nil];
    if (oldLic) [fm removeItemAtPath:newCachePath error:nil];
    
    return results;
}

@end
