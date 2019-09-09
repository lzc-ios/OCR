//
//  LFLoadLicense.m
//  BankCardScan
//
//  Created by linkface on 2018/9/7.
//  Copyright © 2018年 SenseTime. All rights reserved.
//

#import "LFLoadLicense.h"
#import "LFEncryption.h"

@implementation LFLoadLicense

//获取license文件地址
+ (void)downLoadLicenseJsonUrl:(NSString *)Url completeBlock:(void (^)(NSDictionary *_Nullable, NSError * _Nullable))completeBlcok{

    NSURL*url=[NSURL URLWithString:Url];
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error == nil){
            NSDictionary *josnDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            completeBlcok(josnDic,nil);
        }else{
            completeBlcok(nil,error);
        }
    }] resume];
    
}

// 下载License文件地址
+ (void)downLoadLicenseUrl:(NSString *)licenseUrl completeBlock:(void (^)(NSString *, NSError * _Nullable))completeBlcok{
    
    NSURL *url = [NSURL URLWithString:licenseUrl];
    [[[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            NSString *licstr = [NSString stringWithContentsOfFile:location.path encoding:NSUTF8StringEncoding error:nil];
            completeBlcok(licstr,nil);
        } else {
            completeBlcok(nil,error);
        }
    }] resume];
    
}

@end
