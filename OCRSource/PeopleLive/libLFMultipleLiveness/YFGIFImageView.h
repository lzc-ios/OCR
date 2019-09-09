//
//  YFGIFImageView.h
//  UIImageView-PlayGIF
//
//  Created by Yang Fei on 14-3-26.
//  Copyright (c) 2014年 yangfei.me. All rights reserved.
//

/*******************************************************
 *  Dependencies:
 *      - QuartzCore.framework
 *      - ImageIO.framework
 *  Parameters:
 *      Pass value to one of them:
 *      - gifData NSData from a GIF
 *      - gifPath local path of a GIF
 *  Usage:
 *      - startGIF
 *      - stopGIF
 *      - isGIFPlaying
 *  P.S.:
 *      Need category? Use UIImageView+PlayGIF.h/m
 *******************************************************/

/*******************************************************
 *  依赖:
 *      - QuartzCore.framework
 *      - ImageIO.framework
 *  参数:
 *      以下传参2选1：
 *      - gifData       GIF图片的NSData
 *      - gifPath       GIF图片的本地路径
 *  调用:
 *      - startGIF      开始播放
 *      - stopGIF       结束播放
 *      - isGIFPlaying  判断是否正在播放
 *  另外：
 *      想用 category？请使用 UIImageView+PlayGIF.h/m
 *******************************************************/

/*******************************************************
 *  GIF View 功能完善
 *  Created by 单硕 on 16-02-19.
 *  增加了对gif图片播放次数的控制，播放完成后的回调，以及播放时间
 *
 *  新增参数：
 *      - repeatMaxCount
 *      - completionBlock
 *
 *  新增方法：
 *      - initWithRepeatMaxCount:
 *      - initWithRepeatMaxCount: withCompletionBlock:
 *      - duration
 *******************************************************/

#import <UIKit/UIImageView.h>

typedef void(^YFGIFImageViewCompletionBlock)();

@interface YFGIFImageView : UIImageView

@property (nonatomic, strong) NSString          *gifPath;
@property (nonatomic, strong) NSData            *gifData;
@property (nonatomic, assign, readonly) CGSize  gifPixelSize;
@property (nonatomic, assign) BOOL restart;
@property (nonatomic, assign) BOOL shouldShowLastFrame; // 播放结束后是否保留最后一帧图片，默认为NO
@property (nonatomic, assign) NSInteger repeatMaxCount; // Gif最大循环数，默认为无穷
@property (nonatomic, copy, readonly) YFGIFImageViewCompletionBlock completionBlock; // 设定Gif图片循环次数后，结束播放时的回调

- (instancetype)initWithRepeatMaxCount:(NSInteger)repeatMaxCount;
- (instancetype)initWithRepeatMaxCount:(NSInteger)repeatMaxCount withCompletionBlock:(YFGIFImageViewCompletionBlock)completionBlock;     // Designed Initializer
- (NSTimeInterval)duration; // Gif的播放时间
- (void)startGIF;
- (void)startGIFWithRunLoopMode:(NSString * const)runLoopMode;
- (void)stopGIF;
- (BOOL)isGIFPlaying;

@end
