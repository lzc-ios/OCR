//
//  LFCapturePhotoViewController.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "LFBankCardMaskView.h"

@interface LFCapturePhotoViewController : UIViewController

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
- (instancetype)initWithLicenesePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard modelPath:(NSString *)modelPath extraPath:(NSString *)extraPath;

@property (nonatomic, assign) AVCaptureVideoOrientation captureOrientation;

@property (nonatomic, assign) CGAffineTransform interfaceTransform;

@property (nonatomic, assign) BOOL isScanVerticalCard;

@property (nonatomic, strong) LFBankCardMaskView *readerView;    // 遮罩view

@end
