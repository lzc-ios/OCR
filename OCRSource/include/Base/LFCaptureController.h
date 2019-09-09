//
//  LFCaptureController.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFCaptureDelegate.h"
#import "LFCaptureMaskView.h"
#import "LFCaptureReaderDelegate.h"
#import "LFCaptureReader.h"
#import "LFCapture.h"


typedef NS_ENUM(NSInteger, DICaptureMode)
{
    kCaptureCard        ,     //2014.11.11 IDCard Detection
    kCaptureCardBack    ,   // 2015.01.13 Capture Card Back
    kCaptureBankCard    ,
};


@protocol LFCaptureDelegate;



@interface LFCaptureController : UIViewController

// appID
@property(nonatomic,copy)NSString *appID;
// appSecret
@property(nonatomic,copy)NSString *appSecret;
// 拍照
@property(nonatomic,assign)NSInteger isAuto;
 //是否开启身份证类型检测
@property(nonatomic,assign)BOOL returnType;
// 横竖卡
@property(nonatomic,assign)NSInteger isVertical;
@property (nonatomic, assign) DICaptureMode iMode;      
@property (nonatomic, weak) id<LFCaptureDelegate> captureDelegate;
@property (nonatomic, strong) LFCaptureReader* captureReader;   // 获取相片
@property (nonatomic, strong) LFCaptureMaskView *readerView;    // 遮罩view
@property (nonatomic, assign) AVCaptureVideoOrientation captureOrientation;
@property (nonatomic, strong) LFCapture *capture;
@property (nonatomic, strong) UIButton *btnChangeScanDirection;
@property (nonatomic, assign) BOOL showAnimation;
@property (nonatomic, strong) UIButton *btnCancel;


@property (nonatomic, readonly, assign) BOOL shouldFullCard; //是否卡片完整才返回

@property (nonatomic, assign) NSInteger autoCancelTime; //未检测到卡片超时时间，0则不做超时检测。

/**
 captureController init

 @param orientation 方向
 @param licenseName 授权文件名 Linkface.lic 传 Linkface
 @param shouldFullCard 是否需要卡片全在扫描框内(四边均在扫描框内)
 @return captureController
 */
- (instancetype)initWithOrientation:(AVCaptureVideoOrientation)orientation licenseName:(NSString *)licenseName shouldFullCard:(BOOL)shouldFullCard __attribute__((deprecated("已过期")));

/**
 captureController init
 
 @param orientation 方向
 @param licensePath 授权文路径
 @param shouldFullCard 是否需要卡片全在扫描框内(四边均在扫描框内)
 @return captureController
 */
- (instancetype)initWithOrientation:(AVCaptureVideoOrientation)orientation licensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard;


/**
 内部方法 停止session
 */
- (void)stop;


/**
 内部方法 更改模式

 @param iMode 模式
 */
- (void)changeCaptureMode:(NSInteger)iMode;

// 内部方法 
- (void)captureReader:(LFCaptureReader *)reader didSnapshot:(UIImage *)image;
// 是否隐藏 mask
- (void)hideMaskView:(BOOL)bHidden;

- (void)didCancel; // 允许其他 Controller 主动控制关闭 LFIDCardScannerController
- (void)autoCancel; // 超时自动关闭

// 处理异常
- (void)receivedErrorNote:(NSNotification *)notification;

// 处理异常
- (void)receivedError: (NSInteger)errorCode;

// 是否处理相机获取的视频流
- (void)doRecognitionProcess:(BOOL)bProcessEnabled;

// 重置自动取消定时器
- (void)resetAutoCancelTimer;

/*! @brief bDebug 调试开关(控制NSLog的输出)
 */
@property (nonatomic, assign)   BOOL    bDebug  ;
// The interface to modify the line color.
- (void)setTheScanLineColor:(UIColor *)color;
// The interface to modify the layer color.
- (void)setTheMaskLayerColor:(UIColor *)color andAlpha:(CGFloat)alpha;

// 调整布局
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation inDuration:(NSTimeInterval)duration;

@end
