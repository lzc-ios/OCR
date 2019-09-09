//
//  LFLivefaceViewController.h
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFLivenessDetectorDelegate.h"

@interface LFLivefaceViewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

/**
 *  设置语音提示默认是否开启 , 不设置时默认为YES即开启.
 */
@property (nonatomic , assign) BOOL bVoicePrompt;


/**
 *  初始化方法
 *
 *  @param fDuration            每个模块允许的最大检测时间,小于等于0时为不设置超时时间.
 *  @param strBundlePath        资源路径
 *  @param strLicensePath       license的路径
 *
 *  @return 活体检测器实例
 */
- (instancetype)initWithDuration:(double)fDuration
             resourcesBundlePath:(NSString *)strBundlePath;


/**
 *  活体检测器配置方法 , 需要在 setOutputType:complexity: 之前调用.
 *
 *  @param delegate     回调代理
 *  @param queue        回调线程
 *  @param arrDetection 动作序列, 如 @[@(LIVE_BLINK) ,@(LIVE_MOUTH) ,@(LIVE_NOD) ,@(LIVE_YAW)] , 参照 LFLivenessEnumType.h
 */
- (void)setDelegate:(id <LFLivenessDetectorDelegate>)delegate
      callBackQueue:(dispatch_queue_t)queue
  detectionSequence:(NSArray *)arrDetection;


/**
 *  设置活体检测器默认输出方案及难易度, 可根据需求在 startDetection 之前调用使生效.需要在 setDelegate:callBackQueue:detectionSequence: 之后调用.
 *
 *  @param iOutputType 活体检测成功后的输出方案, 默认为 LIVE_OUTPUT_SINGLE_IMAGE
 *  @param iComplexity 活体检测的复杂度, 默认为 LIVE_COMPLEXITY_NORMAL
 */
- (void)setOutputType:(LivefaceOutputType)iOutputType
           complexity:(LivefaceComplexity)iComplexity;


/**
 *  开始检测, 检测的输出方案以及难易程度为之前最近一次调用 setOutputType:complexity: 所指定方案及难易程度.
 */
- (void)startDetection;



/**
 *  取消检测
 */
- (void)cancelDetection;



/**
 *  获取SDK版本
 *
 *  @return SDK版本
 */
+ (NSString *)getSDKVersion;

@end
