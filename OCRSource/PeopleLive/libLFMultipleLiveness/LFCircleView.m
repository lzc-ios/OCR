//
//  LFCircleView.m
//  LFLivenessController
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFCircleView.h"

@interface LFCircleView ()

@property (nonatomic , assign) CGFloat fBodyWidth;

@property (nonatomic , strong) UIColor *colorB;

@property (nonatomic , strong) UIFont *font;

@property (nonatomic , strong) UIColor *colorT;

@property (nonatomic , strong) UILabel *lblNumber;

@property (nonatomic , assign) NSInteger iLastNumber;

@property (nonatomic , assign) double dMaxNumber;

@end

@implementation LFCircleView

- (instancetype)initWithFrame:(CGRect)frame bodyWidth:(CGFloat)fWidth bodyColor:(UIColor *)colorB font:(UIFont *)font textColor:(UIColor *)colorT MaxNumber:(double)dMaxNumber;
{
    if (self = [super initWithFrame:frame]) {
        _fBodyWidth = fWidth;
        _colorB = colorB;
        _font = font;
        _colorT = colorT;
        self.layer.cornerRadius = CGRectGetWidth(frame) / 2;
        self.clipsToBounds = YES;
        self.iLastNumber = 0;
        self.dMaxNumber = dMaxNumber;
        [self addSubview:self.lblNumber];
    }
    return self;
}

#pragma - mark lazy load
#pragma - mark

- (UILabel *)lblNumber
{
    if (!_lblNumber) {
        _lblNumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width - _fBodyWidth, self.frame.size.height - _fBodyWidth)];
        _lblNumber.backgroundColor = [UIColor clearColor];
        _lblNumber.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        _lblNumber.layer.cornerRadius = (self.frame.size.width - _fBodyWidth) / 2;
        _lblNumber.clipsToBounds = YES;
        _lblNumber.textColor = _colorT;
        _lblNumber.textAlignment = NSTextAlignmentCenter;
        _lblNumber.font = _font;
        _lblNumber.adjustsFontSizeToFitWidth = YES;
    }
    return _lblNumber;
}

- (void)drawRect:(CGRect)rect
{
    
    [self drawWithAnglePercent];
}

- (void)setFAnglePercent:(double)fAnglePercent
{
    if (fAnglePercent > 1.0) {
        fAnglePercent = 0.000001;
    }
    
    _fAnglePercent = fAnglePercent;
    [self setNeedsDisplay];
}


- (void)drawWithAnglePercent
{
    int iNumber = (int)((1.0 - self.fAnglePercent) * self.dMaxNumber);
    
    if (iNumber != self.iLastNumber) {
        self.lblNumber.text = [NSString stringWithFormat:@"%d" , iNumber];
        self.iLastNumber = iNumber;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextAddArc(context , self.bounds.size.width / 2 ,
                    self.bounds.size.height / 2 ,
                    self.bounds.size.width / 2 - _fBodyWidth / 2,
                    -M_PI_2 ,
                    M_PI_2 * 3,
                    0);
    CGContextSetLineWidth(context, _fBodyWidth);
    CGContextSetStrokeColorWithColor(context, _colorB.CGColor);
    CGContextStrokePath(context);
    
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    
    CGContextAddArc(context ,
                    self.bounds.size.width / 2 ,
                    self.bounds.size.height / 2,
                    self.bounds.size.width / 2 - _fBodyWidth / 2 ,
                    -M_PI_2,
                    -M_PI_2 + (self.fAnglePercent - 1) * M_PI * 2 ,
                    0);
    
    CGContextSetLineWidth(context, _fBodyWidth + 1);
    CGContextStrokePath(context);
}

@end
