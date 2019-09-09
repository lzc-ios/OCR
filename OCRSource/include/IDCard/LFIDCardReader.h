//
//  LFIDCardReader.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFCaptureReader.h"
#import "LFIDCardMaskView.h"
#import <OCR_SDK/OCR_SDK.h>

@interface LFIDCardReader : LFCaptureReader

// appID
@property(nonatomic,copy)NSString *appID;
// appSecret
@property(nonatomic,copy)NSString *appSecret;
// 拍照
@property(nonatomic,assign)NSInteger isAuto;
// 横竖卡
@property(nonatomic,assign)NSInteger isVertical;
// 是否开启身份证类型
@property(nonatomic,assign)BOOL returnType;

/**
 reader init
 
 @param licenseName 授权文件名
 @param shouldFullCard 是否整卡才返回
 @return LFCaptureReader 对象
 */
- (instancetype)initWithLicenseName:(NSString *)licenseName shouldFullCard:(BOOL)shouldFullCard;

- (instancetype)initWithLicensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard;

- (instancetype)initWithLicensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard modelPath:(NSString *)modelPath;

@property (nonatomic, weak) LFIDCardMaskView *maskView;
@property (nonatomic, strong) UIImage *resultImage;

/*! @brief bDebug 调试开关(控制NSLog的输出)
 */
@property (nonatomic, assign) BOOL bDebug;

- (void)moveWindowVerticalFromCenterWithDelta:(int)iDelta;  //  iDelta == 0 in center , < 0 move up, > 0 move down

- (void)setMode:(LFIDCardMode)mode;

- (void)setRecognizeItemOption:(LFIDCardItemOption)option;

- (void)setHintLabel:(UILabel *)label;


@end
