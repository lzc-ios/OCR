//
//  LFCaptureMaskView.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFCaptureMaskView.h"
@interface LFCaptureMaskView () {

}

@end

@implementation LFCaptureMaskView

#pragma mark - life cycle
- (instancetype)initWithFrame:(CGRect)frame andWindowFrame:(CGRect)windowFrame Orientation:(UIInterfaceOrientation)orientation{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        self.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;//important for rotate
        CGFloat newHeight = windowFrame.size.height * [self modifyYRatio];
        CGFloat newY = windowFrame.origin.y - (newHeight - windowFrame.size.height) / 2.0;
        self.windowFrame = CGRectMake(windowFrame.origin.x, newY, windowFrame.size.width, newHeight);
//        self.windowFrame = windowFrame;
        self.orientation = orientation;
        switch (self.orientation) {
            case UIInterfaceOrientationLandscapeLeft:
                self.interfaceTransform = CGAffineTransformMakeRotation(M_PI_2 * 3);
                break;
            case UIInterfaceOrientationLandscapeRight:
                self.interfaceTransform = CGAffineTransformMakeRotation(M_PI_2);
                break;
            case UIInterfaceOrientationPortrait:
            default:
                self.interfaceTransform = CGAffineTransformMakeRotation(0);
                break;
        }
        _maskCoverView = [[LFMaskView alloc] initWithFrame:self.bounds];
        _maskCoverView.windowRect = self.windowFrame;
        [self addSubview: _maskCoverView];
    }
    
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        self.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;//important for rotate
    }
    return self;
}

- (void)changeScanWindowDirection:(BOOL)isVertical{
    
}

- (void) dealloc
{
//    NSLog( @"%@ dealloc", self.class );
}

- (BOOL) isIphone4 {
    return (SCREEN_HEIGHT / SCREEN_WIDTH) == (3.0/2.0) || (SCREEN_HEIGHT / SCREEN_WIDTH) == (2.0/3.0);
}

- (CGFloat)modifyYRatio {
    CGFloat videoRatio = 720.0 / 1280.0;
    CGFloat uiRatio = CGRectGetWidth(self.bounds) / CGRectGetHeight(self.bounds);
    
//    CGFloat videoRatio = 1280.0 / 720.0;
//    CGFloat uiRatio = CGRectGetHeight(self.bounds) / CGRectGetWidth(self.bounds);
    return uiRatio / videoRatio;
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    _maskCoverView.windowRect = self.windowFrame;
    [_maskCoverView setNeedsDisplay];
}

#pragma mark - public methods

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{

}

#pragma mark - Setter

- (void)setLineColor:(UIColor *)color {
    _maskCoverView.lineColor = color;
    [_maskCoverView setNeedsDisplay];
}

- (void)setMaskLayerColor:(UIColor *)color andAlpha:(CGFloat)alpha {
    _maskCoverView.maskColor = color;
    _maskCoverView.maskAlpha = alpha;
    [_maskCoverView setNeedsDisplay];
}

@end

@implementation LFMaskView
{
    CGContextRef _context;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.lineColor = [UIColor whiteColor];
        self.maskAlpha = 0.8;
        self.maskColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    _context = UIGraphicsGetCurrentContext();
    CGFloat redColor = 12;
    CGFloat blueColor = 12;
    CGFloat greenColor = 12;
    [self.maskColor getRed:&redColor green:&greenColor blue:&blueColor alpha:nil];
    UIColor *maskColor = [UIColor colorWithRed:redColor green:greenColor blue:blueColor alpha:self.maskAlpha];
    [maskColor setFill];
    CGContextFillRect(_context, self.bounds);
    CGContextClearRect(_context, self.windowRect);
//    _context = UIGraphicsGetCurrentContext();
    
    CGFloat fLineWidth = 2;
    CGFloat fLineLength = 40;
    
    CGContextMoveToPoint(_context, self.windowRect.origin.x - fLineWidth/2, self.windowRect.origin.y + fLineLength);
    CGContextAddLineToPoint(_context, self.windowRect.origin.x - fLineWidth/2, self.windowRect.origin.y - fLineWidth/2);
    CGContextAddLineToPoint(_context, self.windowRect.origin.x + fLineLength, self.windowRect.origin.y - fLineWidth/2);
    
    CGContextMoveToPoint(_context, self.windowRect.origin.x + self.windowRect.size.width - fLineLength, self.windowRect.origin.y - fLineWidth/2);
    CGContextAddLineToPoint(_context, self.windowRect.origin.x + self.windowRect.size.width + fLineWidth/2, self.windowRect.origin.y - fLineWidth/2);
    CGContextAddLineToPoint(_context, self.windowRect.origin.x + self.windowRect.size.width + fLineWidth/2, self.windowRect.origin.y + fLineLength);
    
    CGContextMoveToPoint(_context, self.windowRect.origin.x - fLineWidth/2, self.windowRect.origin.y + self.windowRect.size.height - fLineLength);
    CGContextAddLineToPoint(_context, self.windowRect.origin.x - fLineWidth/2, self.windowRect.origin.y + self.windowRect.size.height + fLineWidth/2);
    CGContextAddLineToPoint(_context, self.windowRect.origin.x + fLineLength , self.windowRect.origin.y + self.windowRect.size.height + fLineWidth/2);
    
    CGContextMoveToPoint(_context, self.windowRect.origin.x + self.windowRect.size.width - fLineLength, self.windowRect.origin.y + self.windowRect.size.height + fLineWidth/2);
    CGContextAddLineToPoint(_context, self.windowRect.origin.x + self.windowRect.size.width + fLineWidth/2, self.windowRect.origin.y + self.windowRect.size.height + fLineWidth/2);
    CGContextAddLineToPoint(_context, self.windowRect.origin.x + self.windowRect.size.width + fLineWidth/2 , self.windowRect.origin.y + self.windowRect.size.height - fLineLength);
    
    
    [self.lineColor set];
    CGContextSetLineWidth(_context, fLineWidth);
    
    CGContextStrokePath(_context);
}

@end
