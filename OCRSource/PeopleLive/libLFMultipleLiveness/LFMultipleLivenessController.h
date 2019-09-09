//
//  LFMultipleLivenessController.h
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 动作版活体检测类型
typedef NS_ENUM(NSUInteger, LFDetectionType) {
    /// 无动作
    LFDETECTION_NONE,
    
    /// 眨眼检测
    LFLIVEFACE_BLINK,
    
    /// 张闭嘴检测
    LFLIVEFACE_MOUTH,
    
    /// 上下点头检测
    LFLIVEFACE_NOD,
    
    /// 左右摇头检测
    LFLIVEFACE_YAW
};

typedef NS_ENUM(NSUInteger, LFMultipleLivenessError) {
    /// 算法SDK初始化失败
    LFMultipleLivenessInitFaild,
    
    /// 相机权限获取失败
    LFMultipleLivenessCameraError,
    
    /// 人脸变更
    LFMultipleLivenessFaceChanged,
    
    /// 动作超时
    LFMultipleLivenessTimeOut,
    
    /// 应用即将被挂起
    LFMultipleLivenessWillResignActive,
        
    /// 内部错误
    LFMultipleLivenessInternalError,
    
    /// 解析Json指令失败
    LFMultipleLivenessBadJson,
    
    /// 包名错误
    LFMultipleLivenessBundleIDError,
    
    /// 证书过期
    LFMultipleLivenessAuthExpire,
    
    /// license 文件不合法
    LFMultipleLivenessLicenseError,
    
    /// 模型u过期
    LFMultipleLivenessModelError,
    
    /// 其他错误
    LFMultipleLivenessOtherError,
    
    /// 资源文件加载失败
    LFMultipleLivenessSourceError
    
};

@protocol LFMultipleLivenessDelegate <NSObject>

@optional

/*!
 @method LFMultiLivenessDidStart
 @abstract
 活体检测已经开始的回调.
 @discussion
 用于记录次数或者进行标记等.
 */
- (void)multiLivenessDidStart;

@required

/*!
 @method multiLivenessDidSuccessfulGetData:
 @abstract
 活体检测成功回调
 @param encryTarData       回传加密后的二进制数据
 @param arrLFImage 根据指定输出方案回传 LFImage 数组 , LFImage属性见 LFImage.h
 @param lfVideoData根据指定输出方案回传 NSData 视频数据
 */
- (void)multiLivenessDidSuccessfulGetData:(nullable NSData *)encryTarData
                                 lfImages:(nullable NSArray *)arrLFImage
                              lfVideoData:(nullable NSData *)lfVideoData;

/*!
 @method multiLivenessDidFailWithType:
 @abstract
 活体检测失败回调方法.
 @param LFMultipleLivenessError iErrorType 表示错误类型.
 @param LFDetectionType iDetectionType 发生错误时的检测类型
 @param NSInteger iIndex 发生错误时检测模块的索引值 , 0 是第一个 .
 @param NSData * encryTarData 检测失败后携带的加密数据 , 压缩失败,加密失败,解析Json指令失败及未指定输出方案或检测方案返回为 nil.
 @param arrLFImage      根据指定输出方案回传 LFImage 数组 , LFImage属性见 LFImage.h
 @param lfVideoData     根据指定输出方案回传 NSData 视频数据
 @discussion
 用于当人脸变更或者超时等失败时由外部控制是否可以重试.根据错误类型弹出alert等.
 */
- (void)multiLivenessDidFailWithType:(LFMultipleLivenessError)iErrorType
                       DetectionType:(LFDetectionType)iDetectionType
                      DetectionIndex:(NSInteger)iIndex
                                Data:(nullable NSData *)encryTarData
                            lfImages:(nullable NSArray *)arrLFImage
                         lfVideoData:(nullable NSData *)lfVideoData;

/*!
 @method LFMultiLivenessDidCancel
 @abstract
 取消活体检测指令回调方法.
 @discussion
 当活体检测被取消时将会回调此方法.
 */
- (void)multiLivenessDidCancel;

@end

@interface LFMultipleLivenessController : UIViewController

/// 回调代理
@property (nonatomic, weak) id <LFMultipleLivenessDelegate>delegate;

/// 设置 json string , 返回 是否成功
- (BOOL)setJsonCommand:(NSString *)strJsonCommand;

/// 默认音频提示开关 , 默认为 YES:开
- (void)setVoicePromptOn:(BOOL)bVoicePrompt;

/// 重试或开始
- (void)restart;

/// 取消检测
- (void)cancel;

/// 获取SDK版本
- (NSString *)getLivenessVersion;

@end
