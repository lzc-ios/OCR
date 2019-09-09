//
//  LFIDCardMaskView.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LFIDCardMaskView.h"


#define RECT_WIDTH          240.0f
#define RECT_HEIGHT         80.0f
#define TOP_LEFT_X          (320.0f-RECT_WIDTH)/2.0f
#define TOP_LEFT_Y          (SCREEN_HEIGHT - RECT_HEIGHT)/2.0f  // (640.0f*320.f/480.f - RECT_HEIGHT)/2.0f
#define BOTTOM_RIGHT_X      TOP_LEFT_X+RECT_WIDTH
#define BOTTOM_RIGHT_Y      TOP_LEFT_Y+RECT_HEIGHT
#define RECT_SIZE           20.0f
#define LINE_BORDER_SIZE    2.0f

#define LABEL_FONT_SIZE 15

#define OUTER_BORDER_RATIO 0.6
#define OUTER_BORDER_HEIGHT_MAX 960
#define OUTER_BORDER_WIDTH_MAX 600
@interface LFIDCardMaskView ()

@property(nonatomic, strong) CALayer *layerUp;
@property(nonatomic, strong) CALayer *layerDown;
@property(nonatomic, strong) UILabel *labelScan;
@property(nonatomic, strong) CALayer *layerLine;

@end


@implementation LFIDCardMaskView

@synthesize layerUp = _layerUp;
@synthesize layerDown = _layerDown;
@synthesize labelScan = _labelScan;

#pragma mark - lazy initialize

- (CALayer *)layerLine {
    if (!_layerLine) {
        _layerLine = [CALayer new];
        _layerLine.borderColor = [[UIColor greenColor] CGColor];
        _layerLine.borderWidth = 5;
    }
    return _layerLine;
}


#pragma mark - inside mothods

- (void)setLabel:(UILabel *)label {
    self.labelScan.text = label.text;
    self.labelScan.textColor = label.textColor;
}

#pragma mark - life cycle
-(instancetype)initWithFrame:(CGRect)frame andWindowFrame:(CGRect)windowFrame Orientation:(UIInterfaceOrientation)orientation{
    self = [super initWithFrame:frame andWindowFrame:windowFrame Orientation:orientation];
    if (self) {
        _labelScan = [[UILabel alloc] init];
        [_labelScan setBackgroundColor:[UIColor clearColor]];
        [_labelScan setTextColor:[UIColor whiteColor]];
        [_labelScan setFont:[UIFont systemFontOfSize:LABEL_FONT_SIZE]];
        [_labelScan setFrame:CGRectMake(0, 0, SCREEN_WIDTH, 30)] ; // CGRectMake(0.0f, 80.0f, SCREEN_WIDTH, SCREEN_HEIGHT- rectFrame.origin.y)];
        if (orientation == UIInterfaceOrientationPortrait) {
            _labelScan.center = CGPointMake(CGRectGetMidX(self.windowFrame), CGRectGetMinY(self.windowFrame) - CGRectGetHeight(self.windowFrame)/6);
        }else if (orientation == UIDeviceOrientationLandscapeRight){
            _labelScan.center = CGPointMake(CGRectGetWidth(self.windowFrame)/10, CGRectGetMidY(self.windowFrame));
        }else if (orientation == UIDeviceOrientationLandscapeLeft){
            _labelScan.center = CGPointMake(CGRectGetMaxX(self.windowFrame) + CGRectGetWidth(self.windowFrame)/10, CGRectGetMidY(self.windowFrame));
        }
        [_labelScan setTextAlignment:NSTextAlignmentCenter] ;
        [_labelScan setNumberOfLines:10];
        _labelScan.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.7].CGColor;
        _labelScan.layer.shadowOffset = CGSizeMake(7, 7);
        _labelScan.layer.shadowOpacity = 1.0;
        _labelScan.layer.shadowRadius = 5.0;
        _labelScan.transform = self.interfaceTransform;
        _labelScan.text = @"请将身份证放入扫描框内" ;
        _labelScan.numberOfLines = 2;
        [self addSubview:_labelScan];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // Initialization code
        CGFloat newHeight = self.windowFrame.size.height * [self modifyYRatio];
        CGFloat newY = self.windowFrame.origin.y - (newHeight - self.windowFrame.size.height) / 2.0;
        self.windowFrame = CGRectMake(self.windowFrame.origin.x, newY, self.windowFrame.size.width, newHeight);
        
        self.layerLine.frame = self.windowFrame;
        [self.layer addSublayer:self.layerLine];
        
        _labelScan = [[UILabel alloc] init];
        [_labelScan setBackgroundColor:[UIColor clearColor]];
        [_labelScan setTextColor:[UIColor whiteColor]];
        [_labelScan setFont:[UIFont systemFontOfSize:LABEL_FONT_SIZE]];
        [_labelScan setFrame:self.layerUp.frame] ; // CGRectMake(0.0f, 80.0f, SCREEN_WIDTH, SCREEN_HEIGHT- rectFrame.origin.y)];
        [_labelScan setTextAlignment:NSTextAlignmentCenter] ;
        [_labelScan setNumberOfLines:10];
        [self addSubview:_labelScan];
        _labelScan.text = @"提示：\n\n1.请将身份证边框与绿框重合；\n\n2.请保持稳定和图像清晰。" ;

    }
    return self;
}

# pragma mark - Scan line Methods

- (void)dealloc {
    
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}


- (void)moveWindowDeltaY:(int) iDeltaY  //  fDeltaY == 0 in center , < 0 move up, > 0 move down
{
    CGRect rectFrame = self.windowFrame;
    if (rectFrame.size.height < rectFrame.size.width) {
        rectFrame.origin.y += (CGFloat)iDeltaY;
    }
    self.windowFrame = rectFrame;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        self.windowFrame = CGRectMake(self.windowFrame.origin.x + self.windowFrame.size.width *0.1,
                                      self.windowFrame.origin.y + self.windowFrame.size.height *0.1,
                                      self.windowFrame.size.width *0.8,
                                      self.windowFrame.size.height *0.8);
    }

    self.layerLine.frame = self.windowFrame;
    _labelScan.center = CGPointMake(CGRectGetMidX(self.windowFrame), CGRectGetMinY(self.windowFrame) - CGRectGetHeight(self.windowFrame)/6);
    [self setNeedsDisplay];
}

@end
