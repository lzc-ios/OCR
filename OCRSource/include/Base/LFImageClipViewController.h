//
//  LFImageClipViewController.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class LFImageClipViewController;

@protocol LFImageClipDelegate <NSObject>

- (void)imageCropper:(LFImageClipViewController *)clipViewController didFinished:(UIImage *)editedImage;
- (void)imageCropperDidCancel:(LFImageClipViewController *)clipViewController;

@end

@interface LFImageClipViewController : UIViewController

@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) CGRect cropFrame;
@property (nonatomic, weak) id<LFImageClipDelegate> delegate;

- (instancetype)initWithImage:(UIImage *)originalImage cropFrame:(CGRect)cropFrame limitScaleRatio:(NSInteger)limitRatio captureOrientation:(AVCaptureVideoOrientation)captureOrientation;
- (instancetype)initWithImage:(UIImage *)originalImage cropFrame:(CGRect)cropFrame limitScaleRatio:(NSInteger)limitRatio messageTitle:(NSString*)messageTitle captureOrientation:(AVCaptureVideoOrientation)captureOrientation;

@end
