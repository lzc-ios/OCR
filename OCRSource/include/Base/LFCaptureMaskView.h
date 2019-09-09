//
//  LFCaptureMaskView.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFCommon.h"

@interface LFMaskView : UIView

@property (nonatomic, assign) CGRect windowRect;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *maskColor;
@property (nonatomic, assign) CGFloat maskAlpha;

@end

// 遮罩view
@interface LFCaptureMaskView : UIView
@property (nonatomic, assign) CGRect windowFrame;
@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, assign) CGAffineTransform interfaceTransform;
@property (nonatomic) LFMaskView *maskCoverView;

- (instancetype)initWithFrame:(CGRect)frame andWindowFrame:(CGRect)windowFrame Orientation:(UIInterfaceOrientation)orientation;
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation) orientation duration:(NSTimeInterval)duration;

- (CGFloat)modifyYRatio;

- (void)setLineColor:(UIColor *)color;

- (void)setMaskLayerColor:(UIColor *)color andAlpha:(CGFloat) alpha;

- (void)changeScanWindowDirection:(BOOL)isVertical;
@end

