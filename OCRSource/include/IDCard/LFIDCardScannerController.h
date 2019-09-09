//
//  LFIDCardScannerController ： 身份证扫描控制器
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.

#import "LFCaptureController.h"
#import <OCR_SDK/OCR_SDK.h>

typedef NS_OPTIONS(NSInteger, LFIDCardErrorCode) {
    // 单图识别失败
    kIDCardIdentifyFailed = 0,
    // 获取相机权限失败
    kIDCardCameraAuthorizationFailed = 1,
    // 初始化失败
    kIDCardHandleInitFailed = 2,
    // 无效参数
    kIDCardHandleParameterFaild = 3,
    // 句柄错误、内存不足、运存失败、定义缺失、不支持图像格式、
    kIDCardHandleError = 4,
    // 文件不存在
    kIDCardFILENOTFOUND = 5,
    // 模型格式不正确
    kIDCardModelError = 6,
    // 模型文件过期
    kIDCardModelExpire = 7,
    // license文件不合法
    kIDCardLicenseError = 8,
    // 包名错误
    kIDCardAppIDError = 9,
    // SDK过期
    kIDCardSDKExpire = 10,
};

@protocol LFIDCardScannerControllerDelegate <LFCaptureDelegate>

@optional

/**
 获取身份证图片和识别结果

 @param imgSnap 图片
 @param idCardInformation 识别结果
 */
- (void)getCard:(UIImage *)imgSnap withInformation:(LFIDCard *)idCardInformation;
// 获取身份证识别结果
- (void)getCardResult:(LFIDCard *)idcard;
// 识别出错
- (void)getError:(LFIDCardErrorCode)errorCode;

@end

/*! @brief LFIDCardScannerController 函数类
 *
 * 该类封装了带有摄像头的全自动身份证检测和识别功能
 */

@interface LFIDCardScannerController : LFCaptureController

@property (nonatomic, weak) id<LFIDCardScannerControllerDelegate> delegate;

/*! @brief hideMaskView 控制是否显示内置的取景框和提示
 *
 *  @param bHide
 *          NO ： 不隐藏默认取景框和提示文字 （default）
 *          YES： 隐藏默认的取景框和提示文字，用于开发者自定义取景框界面
 *
 *         注意：
 *              该方法在 present 出了 LFIDCardScannerController 之后或
 *              继承了 LFIDCardScannerController 的 viewDidLoad {} 中调用才能生效
 */
 - (void)hideMaskView:(BOOL)bHide;

/*! @brief moveWindowVerticalFromCenterWithDelta 调整取景框的位置(竖屏生效)
 *                  用于开发者自定义取景框，从中央上上下移动是为了在不同屏幕上的适配问题
 *                  用于和定义的界面保持一致
 *
 *  @param iDeltaY  取景框从中央位置上下移动的偏移量
 *          >0：    取景框从中央位置下移
 *          <0：    取景框从中央位置上移
 */
- (void)moveWindowVerticalFromCenterWithDelta:(int)iDeltaY;

/*! @brief doRecognitionProcess 设置是否进行视频帧的识别处理
 *
 *  @param bProcessEnabled
 *          YES：    对从设置起后的每帧都进行身份证识别处理 （默认值）
 *          NO：     对从设置起后的每帧都不做识别处理，还保留视频播放
 */
- (void)doRecognitionProcess:(BOOL)bProcessEnabled;

/*! @brief didCancel 程序控制关闭摄像头并取消 LFIDCardScannerController
 *
 *      请使用其他 Controller 调用 LFIDCardScannerController 的 didCancel 来控制摄像头的关闭，如用于超时控制；
 *      也可继承本类，通过重载 didCancel 来控制关闭的方式和时机 。
 */
- (void)didCancel; // 允许其他 Controller 主动控制关闭 LFIDCardScannerController

/*! @brief cardMode 控制识别身份证哪个面：
 *              0 - kIDCardSmart     - 智能检测 （default）
 *              1 - kIDCardFrontal   - 正面 ,
 *              2 - kIDCardBack      - 反面,
 *
 *         注意：
 *              该方法在 present 出了 LFIDCardScannerController 之后或
 *              继承了 LFIDCardScannerController 的 viewDidLoad {} 中调用才能生效
 */
@property (nonatomic, assign) LFIDCardMode cardMode;


/*! @brief snapshotSeconds 是否在扫描的时候获取快照。默认-1，需要则设置时间间隔，单位：秒
 */
@property (nonatomic, assign) NSInteger snapshotSeconds;


/*! @brief callDelegate_getCard: withInformation: 支持自定义扫描成功后的处理流程，支持预览结果和重扫；
 *  @param image 扫描窗区域的截图，包含含有完整身份证边缘的用于识别的图像
 *  @param LFIDCard 身份证识别的结果，含识别出的文字信息
 *
 *  该方法用于自定义扫描出结果后的流程；
 *  默认是暂停识别处理，给delegate返回识别的图像 image 和识别结果 LFIDCard。
 *  开发者可以继承本类后，重定义识别后的流程，例如给用户展示结果，支持重新扫描或确认结果后结束扫描。
 */
- (void)callDelegate_getCard:(UIImage *)image withInformation:(LFIDCard *)LFIDCard;


/**
 内部方法 处理识别失败

 @param errorCode 识别错误码
 */
- (void)receivedError:(NSInteger)errorCode;


/**
 设置识别信息

 @param option 识别类型
 */
- (void)setRecognizeItemOption:(LFIDCardItemOption)option;

/**
 返回扫描框坐标

 @return maskView rect
 */
- (CGRect)maskWindowRect;

/**
 @param label 设置提示label的文本和字体颜色
 */
- (void)setHintLabel:(UILabel *)label;

@end
