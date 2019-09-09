//
//  LFBankCardCaputreReader.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "LFCaptureReader.h"
#import "LFBankCardMaskView.h"

@interface LFBankCardReader : LFCaptureReader

// appID
@property(nonatomic,copy)NSString *appID;
// appSecret
@property(nonatomic,copy)NSString *appSecret;
// 拍照
@property(nonatomic,assign)NSInteger isAuto;
// 横竖卡
@property(nonatomic,assign)NSInteger isVertical;

/**
 reader init
 
 @param licenseName 授权文件名
 @param shouldFullCard 是否整卡才返回
 @return LFCaptureReader 对象
 */
- (instancetype)initWithLicenseName:(NSString *)licenseName shouldFullCard:(BOOL)shouldFullCard __attribute__((deprecated("已过期, 现已使用授权文件路径方式")));

/*!
 @brief init
 @param licenseNamePath 授权文件路径
 @param shouldFullCard 是否整卡才返回
 @return LFCaptureReader 对象
 */
- (instancetype)initWithLicensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard;

/*!
@brief init
@param licenseNamePath 授权文件路径
@param shouldFullCard 是否整卡才返回
@param modelPath bankcard路径
@param extraPath bankextra路径
@return LFCaptureReader 对象
*/
- (instancetype)initWithLicenesePath:(NSString *)licenesePath shouldFullCard:(BOOL)shouldFullCard modelPath:(NSString *)modelPath extraPath:(NSString *)extraPath;

@property (nonatomic, weak) LFBankCardMaskView *maskView;
@property (nonatomic, strong) UIImage *resultImage;

//@property (nonatomic, assign) BOOL isScanVerticalCard;

/*! @brief bDebug 调试开关(控制NSLog的输出)
 */
@property (nonatomic, assign) BOOL bDebug;


- (void)moveWindowVerticalFromCenterWithDelta:(int)iDelta;  //  iDelta == 0 in center , < 0 move up, > 0 move down

- (void)changeScanWindowToVertical:(BOOL)isVertical;

@end
