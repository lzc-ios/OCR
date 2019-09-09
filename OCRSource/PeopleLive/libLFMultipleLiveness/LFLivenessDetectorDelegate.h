//
//  LFLivenessDetectorDelegate
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFLivenessEnumType.h"
#import "LFImage.h"

/**
 *  活体检测器代理
 */
@protocol LFLivenessDetectorDelegate <NSObject>

@optional

/**
 *  每个检测模块开始的回调方法
 *
 *  @param iDetectionType  当前开始检测的模块类型
 *  @param iDetectionIndex 当前开始检测的模块在动作序列中的位置, 从0开始.
 */
- (void)livenessDidStartDetectionWithDetectionType:(LivefaceDetectionType)iDetectionType
                                    detectionIndex:(int)iDetectionIndex;

/**
 *  每一帧数据回调一次,回调当前模块已用时间及当前模块允许的最大处理时间.
 *
 *  @param dPast             当前模块检测已用时间
 *  @param dDurationPerModel 当前模块检测总时间
 */
- (void)livenessTimeDidPast:(double)dPast
           durationPerModel:(double)dDurationPerModel;

/** 帧率 */
- (void)videoFrameRate:(int)rate;

@required

/**
 *  活体检测成功回调
 *
 *  @param data       回传加密后的二进制数据
 *  @param arrLFImage 根据指定输出方案回传 LFImage 数组 , LFImage属性见 LFImage.h
 *  @param lfVideoData根据指定输出方案回传 NSData 视频数据

 */
- (void)livenessDidSuccessfulGetData:(nullable NSData *)data
                            lfImages:(nullable NSArray *)arrLFImage
                         lfVideoData:(nullable NSData *)lfVideoData;


/**
 *  活体检测失败回调
 *
 *  @param iErrorType      失败的类型
 *  @param iDetectionType  失败时的检测模块类型
 *  @param iDetectionIndex 失败时的检测模块在动作序列中的位置, 从0开始
 *  @param data            回传加密后的二进制数据
 *  @param arrLFImage      根据指定输出方案回传 LFImage 数组 , LFImage属性见 LFImage.h
 *  @param lfVideoData     根据指定输出方案回传 NSData 视频数据
 */
- (void)livenessDidFailWithErrorType:(LivefaceErrorType)iErrorType
                       detectionType:(LivefaceDetectionType)iDetectionType
                      detectionIndex:(int)iDetectionIndex
                                data:(nullable NSData *)data
                            lfImages:(nullable NSArray *)arrLFImage
                         lfVideoData:(nullable NSData *)lfVideoData;

/**
 *  活体检测被取消的回调
 *
 *  @param iDetectionType  检测被取消时的检测模块类型
 *  @param iDetectionIndex 检测被取消时的检测模块在动作序列中的位置, 从0开始
 */
- (void)livenessDidCancelWithDetectionType:(LivefaceDetectionType)iDetectionType
                            detectionIndex:(int)iDetectionIndex;



@end
