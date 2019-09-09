//
//  LFAlertView.m
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFAlertView.h"

@interface LFAlertView ()
{
    UIView *_superView;
}

@property (nonatomic , weak) id <LFAlertViewDelegate> delegate;

@property (nonatomic , strong) UILabel *lblPrompt;
@property (nonatomic,strong) UIView   *backgroundView;   //  底部View,阻挡其他事件响应

@end

@implementation LFAlertView

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (LFAlertView *)initWithTitle:(NSString *)title delegate:(id<LFAlertViewDelegate>)delegate
{
    self = [super initWithFrame:CGRectMake(0, 0, 272.0, 192.0)];
    if (self) {
        
        if (self.delegate != delegate) {
            self.delegate = delegate;
        }
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 5.0f;
        
        self.lblPrompt.text = title;
        [self addSubview:self.lblPrompt];
        
        CGFloat fWidth = self.frame.size.width / 4.0;
        
        NSArray *arrFileNames = @[@"icon_light"   ,
                                  @"icon_phone"   ,
                                  @"icon_glasses" ,
                                  @"icon_time"    ];
        
        NSArray *arrPrompts = @[@"光线充足" ,
                                @"正对手机" ,
                                @"去除遮挡" ,
                                @"放缓速度" ];
        
        for (int i = 0; i < 4; i ++) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 26.0, 26.0)];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.image = [self imagesNamedFromCustomBundle:[arrFileNames objectAtIndex:i]];
            imageView.center = CGPointMake((i + 0.5) * fWidth ,
                                           self.lblPrompt.frame.origin.y + self.lblPrompt.frame.size.height + 37 );
            [self addSubview:imageView];
            
            
            
            UILabel *lblStatic = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, fWidth, 12)];
            lblStatic.textColor = [UIColor blackColor];
            lblStatic.font = [UIFont systemFontOfSize:12];
            lblStatic.text = [arrPrompts objectAtIndex:i];
            lblStatic.textAlignment = NSTextAlignmentCenter;
            lblStatic.center = CGPointMake(imageView.center.x, imageView.frame.origin.y + imageView.frame.size.height + 5 + lblStatic.frame.size.height / 2);
            
            [self addSubview:lblStatic];
        }
        
        UIButton *btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnCancel setFrame:CGRectMake(0, self.frame.size.height - 50.0, self.frame.size.width / 2 + 1, 50.0)];
        [btnCancel setBackgroundImage:[self imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateHighlighted];
        [btnCancel setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [btnCancel setTitle:@"取消" forState:UIControlStateNormal];
        btnCancel.tag = 1000;
        [btnCancel addTarget:self action:@selector(callBackWithButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btnCancel];
        
        UIButton *btnConfirm = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnConfirm setFrame:CGRectMake(self.frame.size.width / 2 - 1, btnCancel.frame.origin.y, self.frame.size.width / 2 + 1, 50.0)];
        [btnConfirm setBackgroundImage:[self imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateHighlighted];
        [btnConfirm setTitleColor:[UIColor colorWithRed:0 green:122.0 / 255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        [btnConfirm setTitle:@"确定" forState:UIControlStateNormal];
        btnConfirm.tag = 1001;
        [btnConfirm addTarget:self action:@selector(callBackWithButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btnConfirm];
        
        UIView *horizontalLine = [[UIView alloc] initWithFrame:CGRectMake(0, btnCancel.frame.origin.y, self.frame.size.width, 0.5)];
        horizontalLine.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:horizontalLine];
        
        UIView *verticalLine = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 0.5, btnCancel.frame.origin.y, 0.5, btnCancel.frame.size.height)];
        verticalLine.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:verticalLine];
        
        self.backgroundView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.backgroundView.backgroundColor = [UIColor blackColor];
        self.backgroundView.alpha = 0.3;
        [[UIApplication sharedApplication].keyWindow addSubview:self.backgroundView];
        
    }
    return self;
}

- (UIImage *)imagesNamedFromCustomBundle:(NSString *)imgName
{
    
    NSString *bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"IImageAssets.bundle"];
    
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    
    NSString *img_path = [bundle pathForResource:imgName ofType:@"png"];
    
    return [UIImage imageWithContentsOfFile:img_path];
}

- (UILabel *)lblPrompt
{
    if (!_lblPrompt) {
        _lblPrompt = [[UILabel alloc] initWithFrame:CGRectMake(0, 26.0, self.frame.size.width, 16)];
        _lblPrompt.textColor = [UIColor blackColor];
        _lblPrompt.textAlignment = NSTextAlignmentCenter;
        _lblPrompt.font = [UIFont systemFontOfSize:16];
    }
    return _lblPrompt;
}

- (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)showOnView:(UIView *)view
{
    _superView = view;
    self.center = CGPointMake(view.frame.size.width / 2.0, view.frame.size.height / 2.0);
    [view addSubview:self];
    [view bringSubviewToFront:self];
}

- (void)hiddenSelf
{
    if (self.superview) {
        
        [self.backgroundView removeFromSuperview];
        [self removeFromSuperview];
    }
    

}

- (UIImage *)imageWithFullFileName:(NSString *)strFileName
{
    return [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:strFileName ofType:@"png"]];
}

- (void)callBackWithButton:(UIButton *)btnSender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [self.delegate tipView:self clickedButtonAtIndex:btnSender.tag - 1000];
    }
    
    [self hiddenSelf];
}

@end
