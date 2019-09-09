//
//  LFBankCardMaskView.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//
#import "LFBankCardMaskView.h"

#import <QuartzCore/QuartzCore.h>


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

#define SCAN_WINDOW_V (CGRectMake(51, 109, 217, 348))

@interface LFBankCardMaskView () {
    
}

@property(nonatomic, strong) UILabel *labelScan;
@property (nonatomic, strong) UIView *readyRectView;

@end


@implementation LFBankCardMaskView
#pragma mark - inside mothods

- (void)setLabelText:(NSString *)text {
    self.labelScan.text = text;
}

#pragma mark - life cycle
- (instancetype)initWithFrame:(CGRect)frame andWindowFrame:(CGRect)windowFrame Orientation:(UIInterfaceOrientation)orientation{
    self = [super initWithFrame:frame andWindowFrame:windowFrame Orientation:orientation];
    if (self) {
        [self setupSubview:orientation];
    }
    return self;
}

-(void)setupSubview:(UIInterfaceOrientation)orientation{
    
    _labelScan = [[UILabel alloc] init];
    [_labelScan setBackgroundColor:[UIColor clearColor]];
    [_labelScan setTextColor:[UIColor whiteColor]];
    [_labelScan setFont:[UIFont systemFontOfSize:LABEL_FONT_SIZE]];
    [_labelScan setFrame:CGRectMake(0, 0, SCREEN_WIDTH, 30)] ; // CGRectMake(0.0f, 80.0f, SCREEN_WIDTH, SCREEN_HEIGHT- rectFrame.origin.y)];
    [_labelScan setTextAlignment:NSTextAlignmentCenter] ;
    [_labelScan setNumberOfLines:10];
    _labelScan.center = [self getLabelCenter:orientation];
    _labelScan.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.7].CGColor;
    _labelScan.layer.shadowOffset = CGSizeMake(7, 7);
    _labelScan.layer.shadowOpacity = 1.0;
    _labelScan.layer.shadowRadius = 5.0;
    _labelScan.transform = self.interfaceTransform;
    _labelScan.text = @"请将银行卡放入扫描框内" ;
    _labelScan.numberOfLines = 2;
    [self addSubview:_labelScan];
    
    CGFloat borderWidth = 4.0;
    CGRect readyRectFrame = CGRectMake(self.windowFrame.origin.x - borderWidth/2.0, self.windowFrame.origin.y - borderWidth/2.0, self.windowFrame.size.width + borderWidth, self.windowFrame.size.height + borderWidth);
    self.readyRectView = [[UIView alloc] initWithFrame:readyRectFrame];
    self.readyRectView.layer.borderColor = [UIColor colorWithRed:83.0/255.0 green:239.0/255.0 blue:160.0/255.0 alpha:1.0].CGColor;
    self.readyRectView.layer.borderWidth = borderWidth;
    [self addSubview: self.readyRectView];
    self.readyRectView.hidden = YES;
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

    CGFloat borderWidth = 4.0;
    CGRect readyRectFrame = CGRectMake(self.windowFrame.origin.x - borderWidth/2.0, self.windowFrame.origin.y - borderWidth/2.0, self.windowFrame.size.width + borderWidth, self.windowFrame.size.height + borderWidth);
    self.readyRectView.frame = readyRectFrame;
    
    if (self.orientation == UIInterfaceOrientationPortrait) {
        _labelScan.center = CGPointMake(CGRectGetMidX(self.windowFrame), CGRectGetMinY(self.windowFrame) - CGRectGetHeight(self.windowFrame)/6);
    }
    
    [self setNeedsDisplay];
}

- (void)changeScanWindowDirection:(BOOL)isVertical{
    CGRect videoWindow = [self getMaskFrame:isVertical];
    
    CGRect realWindow ;
    NSInteger iFitIPhoneSize = 0;

    if (SCREEN_HEIGHT == 480) {
        iFitIPhoneSize = 20; //fit iPhone ratio
    }
    realWindow = CGRectMake(videoWindow.origin.x / VIEDO_WIDTH * SCREEN_WIDTH, videoWindow.origin.y / VIDEO_HEIGHT * SCREEN_HEIGHT - iFitIPhoneSize, videoWindow.size.width / VIEDO_WIDTH * SCREEN_WIDTH, videoWindow.size.height / VIDEO_HEIGHT * SCREEN_HEIGHT + iFitIPhoneSize * 2);
    CGFloat borderWidth = 4.0;
    CGRect readyRectFrame = CGRectMake(realWindow.origin.x - borderWidth/2.0, realWindow.origin.y - borderWidth/2.0, realWindow.size.width + borderWidth, realWindow.size.height + borderWidth);
    self.readyRectView.frame = readyRectFrame;
    
    CGFloat newHeight = realWindow.size.height * [self modifyYRatio];
    CGFloat newY = realWindow.origin.y - (newHeight - realWindow.size.height) / 2.0;
    self.windowFrame = CGRectMake(realWindow.origin.x, newY, realWindow.size.width, newHeight);
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        self.windowFrame = CGRectMake(realWindow.origin.x + realWindow.size.width *0.1, newY + newHeight *0.1, realWindow.size.width *0.8, newHeight *0.8);
    }

//    CGFloat newWidth = realWindow.size.width * [self modifyYRatio];
//    CGFloat newX = realWindow.origin.x - (newWidth - realWindow.size.width) / 2.0;
//    self.windowFrame = CGRectMake(newX, realWindow.origin.y, newWidth, realWindow.size.height);
    
    [self setNeedsDisplay];
    _labelScan.center = [self getLabelCenter:self.orientation];
}

- (CGPoint)getLabelCenter:(UIInterfaceOrientation)orientation{
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGPointMake(CGRectGetMidX(self.windowFrame), CGRectGetMinY(self.windowFrame) - 30);
    }else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGPointMake(self.windowFrame.origin.x - 20, CGRectGetMidY(self.windowFrame));
    }else if (orientation == UIInterfaceOrientationLandscapeRight){
        return CGPointMake(self.windowFrame.origin.x + self.windowFrame.size.width + 20 , CGRectGetMidY(self.windowFrame));
    }
    return CGPointZero;
}

- (CGRect)getMaskFrame:(BOOL)isVertical {
    if (self.orientation == UIDeviceOrientationPortrait) {
        return isVertical?  MASK_WINDOW_V:MASK_WINDOW_H;
    } else {
        return isVertical? MASK_BANKCARD_WINDOW_H:MASK_BANKCARD_WINDOW_V;
    }
}
@end
