//
//  LFCircleView.h
//  LFLivenessController
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFCircleView : UIView

@property (nonatomic, assign) double fAnglePercent;

@property (nonatomic, assign) BOOL bPrepareToDealloc;

- (instancetype)initWithFrame:(CGRect)frame
                    bodyWidth:(CGFloat)fWidth
                    bodyColor:(UIColor *)colorB
                         font:(UIFont *)font
                    textColor:(UIColor *)colorT
                    MaxNumber:(double)dMaxNumber;

@end
