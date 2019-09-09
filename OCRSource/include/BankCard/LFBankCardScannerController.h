//
//  LFBankCardScannerController.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFCaptureController.h"
#import <OCR_SDK/OCR_SDK.h>

typedef NS_OPTIONS(NSInteger, LFBankCardErrorCode) {
    // 单图识别失败
    kBankCardIdentifyFailed = 0,
    // 获取相机权限失败
    kBankCardCameraAuthorizationFailed = 1,
    // 初始化失败
    kBankCardHandleInitFailed = 2,
    // 无效参数
    kBankCardHandleParameterFaild = 3,
    // 句柄错误、内存不足、运存失败、定义缺失、不支持图像格式、
    kBankCardHandleError = 4,
    // 文件不存在
    kBankCardFILENOTFOUND = 5,
    // 模型格式不正确
    kBankCardModelError = 6,
    // 模型文件过期
    kBankCardModelExpire = 7,
    // license文件不合法
    kBankCardLicenseError = 8,
    // 包名错误
    kBankCardAppIDError = 9,
    // SDK过期(lincense文件过期)
    kBankCardSDKExpire = 10,
};

@protocol LFBankCardScannerControllerDelegate <LFCaptureDelegate>

@optional
// 获取银行卡结果
- (void)getCardResult:(LFBankCard *)bankcard;

/**
 获取银行卡图片和识别结果

 @param imgIDCard 图片
 @param bankcard 识别结果
 */
- (void)getCardImage:(UIImage *)imgIDCard withCardInfo:(LFBankCard *)bankcard;
//识别出错
- (void)getError:(LFBankCardErrorCode)errorCode;

@end

@interface LFBankCardScannerController : LFCaptureController


@property (nonatomic, weak) id<LFBankCardScannerControllerDelegate> delegate;

/**
 init
 
 @param orientation 识别方向
 @param licenseName 授权文件名 Linkface.lic 传 Linkface
 @param isVertical  是否是竖卡
 @param shouldFullCard 是否需要卡片全在扫描框内(四边均在扫描框内)
 @return captureController
 */
- (instancetype)initWithOrientation:(AVCaptureVideoOrientation)orientation
                        licenseName:(NSString *)licenseName
                         isVertical:(BOOL)isVertical
                     shouldFullCard:(BOOL)shouldFullCard __attribute__((deprecated("已过期, 现已使用授权文件路径方式")));

/**
 init
 
 @param orientation 识别方向
 @param licensePath 授权文件路径
 @param isVertical  是否是竖卡
 @param shouldFullCard 是否需要卡片全在扫描框内(四边均在扫描框内)
 @return captureController
 */
- (instancetype)initWithOrientation:(AVCaptureVideoOrientation)orientation
                        licensePath:(NSString *)licensePath
                         isVertical:(BOOL)isVertical
                     shouldFullCard:(BOOL)shouldFullCard;

/*! @brief moveWindowVerticalFromCenterWithDelta 调整取景框的位置
 *                  用于开发者自定义取景框，从中央上上下移动是为了在不同屏幕上的适配问题
 *                  用于和定义的界面保持一致
 *
 *  @param iDeltaY    取景框从中央位置上下移动的偏移量
 *          >0：     取景框从中央位置下移
 *          <0：     取景框从中央位置上移
 */
- (void)moveWindowVerticalFromCenterWithDelta:(int)iDeltaY;

/*! @brief doRecognitionProcess 设置是否进行视频帧的识别处理
 *
 *  @param bProcessEnabled
 *          YES：    对从设置起后的每帧都进行身份证识别处理 （默认值）
 *          NO：     对从设置起后的每帧都不做识别处理，还保留视频播放
 */
- (void)doRecognitionProcess:(BOOL)bProcessEnabled;

/*! @brief changeScanWindowForVerticalCard 将扫描框变为扫描竖卡的扫描框
 *
 *  @param isVertical
 *          YES：    扫描框向右旋转
 *          NO：     扫描框向左旋转
 */
- (void)changeScanWindowForVerticalCard:(BOOL)isVertical;


/*! @brief didCancel 程序控制关闭摄像头并取消 LFIDCardScannerController
 *
 *      请使用其他 Controller 调用 LFIDCardScannerController 的 didCancel 来控制摄像头的关闭，如用于超时控制；
 *      也可继承本类，通过重载 didCancel 来控制关闭的方式和时机 。
 */
- (void)didCancel; // 允许其他 Controller 主动控制关闭

// 切换横卡竖卡
- (void)changeScanDirection:(UIButton *)button;

// 是否扫描竖卡
@property (nonatomic, assign) BOOL isScanVerticalCard;


/*! @brief hideChangeScanModeButton 来隐藏控制扫描横竖卡切换的按钮
 *
 *      YES为隐藏，默认不隐藏
 */
@property (nonatomic, assign) BOOL showChangeScanModeButton;

/*! @brief snapshotSeconds 是否在扫描的时候获取快照。默认-1，需要则设置时间间隔，单位：秒
 */
@property (nonatomic, assign) NSInteger snapshotSeconds;


/*! @brief callDelegate_getCard: withInformation: 支持自定义扫描成功后的处理流程，支持预览结果和重扫；
 *  @param image 扫描窗区域的截图，包含含有完整身份证边缘的用于识别的图像
 *  @param bankCard 识别的结果，含识别出的文字信息
 *
 *  该方法用于自定义扫描出结果后的流程；
 *  默认是暂停识别处理，给delegate返回识别的图像 image 和识别结果 bankCard。
 *  开发者可以继承本类后，重定义识别后的流程，例如给用户展示结果，支持重新扫描或确认结果后结束扫描。
 */
- (void)callDelegate_getCard:(UIImage *)image withInformation:(LFBankCard *)bankCard;

// 识别出错(内部方法)
- (void)receivedError:(NSInteger)errorCode;

/**
 返回扫描框坐标
 
 @return maskView rect
 */
- (CGRect)maskWindowRect;
@end
