//
//  LFCaptureReader.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LFCaptureReaderDelegate.h"

enum {
    STOPPED = 0,
    RUNNING = 1,
    PAUSED = 2,
};

@class AVCaptureVideoDataOutput;
@interface LFCaptureReader : NSObject
{
    volatile uint32_t state;
    volatile int32_t channel;
}
@property (nonatomic, assign) AVCaptureVideoOrientation captureVideoOrientation;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieOutput;
@property (nonatomic, unsafe_unretained) id<LFCaptureReaderDelegate> delegate;
@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, assign) CGFloat fScale;
@property (nonatomic, assign) BOOL isAutoFocusSupport;
@property (assign) BOOL adjustingFocus;
@property (nonatomic, assign) bool    bProcessEnabled  ;
@property (nonatomic, assign) BOOL isScanVerticalCard;

@property (nonatomic, assign) CGRect recWindow;

@property (nonatomic, assign) NSInteger iVideoWidth;
@property (nonatomic, assign) NSInteger iVideoHeight;


@property (nonatomic, assign) NSInteger snapshotSeconds;

@property (nonatomic, readonly) CGRect recognizeRect;
@property (nonatomic, readonly) CGRect fullRect;

@property (nonatomic, copy) NSString *licenseName __attribute__((deprecated("已过期, 现已使用授权文件路径方式")));
@property (nonatomic, copy) NSString *licensePath;


/**
 reader init

 @param licenseName 授权文件路径
 @return LFCaptureReader 对象
 */
- (instancetype)initWithLicenseName:(NSString *)licenseName;

- (instancetype)initWithLicensePath:(NSString *)licensePath;

- (instancetype)init NS_UNAVAILABLE;

- (void)willStartRunning;
- (void)willStopRunning;

//- (void)recognizeWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (UIImage *)rotateImage:(UIImage *)image ;

- (void)setVideoOrientation:(AVCaptureVideoOrientation)orientation;

- (CGRect)getMaskFrame;

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;

- (void)setRecognizeRect:(CGRect)recognizeRect inFullRect:(CGRect)fullRect;

-(CGRect)transformRect:(CGRect)oriRect fromRect:(CGRect)fromRect toRect:(CGRect)toRect;
@end
