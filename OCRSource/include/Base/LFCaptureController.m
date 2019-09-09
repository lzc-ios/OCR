//
//  LFCaptureController.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "LFCaptureController.h"
#import "LFCommon.h"
#import "LFCapture.h"
#import "MSWeakTimer.h"
#import <ImageIO/ImageIO.h>

#pragma mark - inline methods

static inline UIImagePickerControllerCameraDevice UICameraForAVPosition (AVCaptureDevicePosition position)
{
    switch (position) {
        case AVCaptureDevicePositionBack:
            return UIImagePickerControllerCameraDeviceRear;
        case AVCaptureDevicePositionFront:
            return UIImagePickerControllerCameraDeviceFront;
        default:
            break;
    }
    return -1;
}

@interface LFCaptureController ()<LFCaptureReaderDelegate>

@property (nonatomic, strong) UIButton *btnTorch;
@property (nonatomic, strong) UIButton *btnFrontCamera;
@property (nonatomic ,strong) UIButton *btnTakeCardBack;
@property (nonatomic, strong) UIButton *btnInput;
@property (nonatomic, strong) UIButton *btnImage;
@property (nonatomic, strong) UIButton *btnRMBScanRank;
@property (nonatomic, strong) UIImagePickerController* imagePicker;
@property (nonatomic, assign) UIInterfaceOrientation lastRotatedInterfaceOrientation;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic) BOOL isHideMaskView;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *maskColor;
@property (nonatomic, assign) CGFloat maskAlpha;

@property (nonatomic, weak) UIView *animationContainerView;
@property (nonatomic, weak) UIImageView *animationView;
@property (nonatomic, assign) NSTimeInterval animationTime;
@property (nonatomic, strong) MSWeakTimer *timeAnimationTimer;
@property (nonatomic, strong) MSWeakTimer *autoCancelTimer;
@property (nonatomic, assign) CGAffineTransform interfaceTransform;
@property (nonatomic, strong) UIImage *animationImage;
@property (nonatomic, strong) UIImage *animationImageLeft;
@property (nonatomic, strong) UIImage *animationImageDown;
@property (nonatomic, strong) UIImage *animationImageRight;

@property (nonatomic, assign) BOOL shouldFullCard; //是否卡片完整才返回

@property (nonatomic, assign) BOOL autoTorch;       // 是否已经自动开启闪光灯

- (void)start;

@end

const static CGFloat kAnimationTime = 4.0;
const static CGFloat kAnimationWidth = 88.0;

@implementation LFCaptureController

- (void)hideMaskView:(BOOL) bHidden
{
    self.readerView.hidden =bHidden;
    self.btnCancel.hidden = bHidden ;
    self.btnTorch.hidden = bHidden;
    self.btnFrontCamera.hidden = bHidden;
    self.btnChangeScanDirection.hidden = bHidden;
    self.isHideMaskView = bHidden;
    if (bHidden || !_showAnimation) {
        self.animationContainerView.hidden = YES;
        [_timeAnimationTimer invalidate];
    } else {
        self.animationContainerView.hidden = NO;
        _timeAnimationTimer = [MSWeakTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(changeTimeView) userInfo:nil repeats:YES dispatchQueue:dispatch_get_main_queue()];
    }
}

- (void) doRecognitionProcess:(BOOL) bProcessEnabled  //YES:(Default)   NO : skip process on each video frame
{
    self.captureReader.bProcessEnabled = bProcessEnabled ;
}


#pragma mark - getter & setter
- (UIButton *)btnCancel
{
    if (!_btnCancel) {
        _btnCancel = [UIButton buttonWithType:UIButtonTypeCustom] ;
        NSBundle *resourceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
        UIImage *imgBtn = [UIImage imageWithContentsOfFile:[resourceBundle pathForResource:@"scan_back" ofType:@"png"]];
        
        switch (self.captureOrientation) {
            case AVCaptureVideoOrientationPortrait:
                _btnCancel.frame = CGRectMake(22, LFStatusBarHeight, 40, 40);
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
                _btnCancel.frame = CGRectMake(22, SCREEN_HEIGHT - 40 - 20, 40, 40);
                break;
            case AVCaptureVideoOrientationLandscapeRight:
                _btnCancel.frame = CGRectMake(SCREEN_WIDTH - 40 - 22, LFStatusBarHeight, 40, 40);
                break;
            default:
                _btnCancel.frame = CGRectMake(22, LFStatusBarHeight, 40, 40);
                break;
        }
        _btnCancel.transform = self.interfaceTransform;
        [_btnCancel setImage:imgBtn forState:UIControlStateNormal];
        [_btnCancel addTarget:self action:@selector(didCancel) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnCancel;
}

- (UIButton *)btnChangeScanDirection {
    if (!_btnChangeScanDirection) {
        _btnChangeScanDirection = [UIButton buttonWithType:UIButtonTypeCustom];
        NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
        UIImage *imageBtn = [UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"scan_horizontal" ofType:@"png"]];
        
        _btnChangeScanDirection.tag = 0;
        switch (self.captureOrientation) {
            case AVCaptureVideoOrientationPortrait:
                _btnChangeScanDirection.frame = CGRectMake(SCREEN_WIDTH - 40 - 22, LFStatusBarHeight, 40, 40);
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
                _btnChangeScanDirection.frame = CGRectMake(22, LFStatusBarHeight, 40, 40);
                break;
            case AVCaptureVideoOrientationLandscapeRight:
                _btnChangeScanDirection.frame = CGRectMake(SCREEN_WIDTH - 40 - 22, SCREEN_HEIGHT - 40 - 20, 40, 40);
                break;
            default:
                _btnChangeScanDirection.frame = CGRectMake(22, LFStatusBarHeight, 40, 40);
                break;
        }
        _btnChangeScanDirection.transform = self.interfaceTransform;
        [_btnChangeScanDirection setImage:imageBtn forState:UIControlStateNormal];
        [_btnChangeScanDirection addTarget:self action:@selector(changeScanDirection:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnChangeScanDirection;
}

#pragma mark - life cycle
- (instancetype)initWithOrientation:(AVCaptureVideoOrientation)orientation licenseName:(NSString *)licenseName shouldFullCard:(BOOL)shouldFullCard
{
    
    self = [self initWithOrientation:orientation licensePath:[[NSBundle mainBundle] pathForResource:licenseName ofType:@"lic"] shouldFullCard:shouldFullCard];
    return self;
}

- (instancetype)initWithOrientation:(AVCaptureVideoOrientation)orientation licensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard {
    
    self = [super init];
    if (self) {
        self.captureOrientation = orientation;
        self.capture = [[LFCapture alloc] init];
        self.shouldFullCard = shouldFullCard;
        
        switch (orientation) {
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
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.captureOrientation = AVCaptureVideoOrientationPortrait;
        self.capture = [[LFCapture alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedErrorNote:) name:@"PostedError" object:nil];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	// Do any additional setup after loading the view.
    [self changeCaptureMode:self.iMode];
    [self setTheScanLineAndLayerColor];
    [self hideMaskView:_isHideMaskView];
    self.btnChangeScanDirection.hidden = YES;
    
    UIView *animationContainerView = [[UIView alloc] init];
    animationContainerView.clipsToBounds = YES;
    [self.view addSubview:animationContainerView];
    self.animationContainerView = animationContainerView;
    animationContainerView.frame = self.readerView.windowFrame;
    
    UIImageView *animationView = [[UIImageView alloc] init];
    animationView.contentMode = UIViewContentModeScaleToFill;
    NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
    UIImage *image = [UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"Group@2x" ofType:@"png"]];
    animationView.image =  [self image:image orientation:UIImageOrientationDown];
    [animationContainerView addSubview:animationView];
    self.animationTime = CFAbsoluteTimeGetCurrent();
    animationView.frame = [self calcRectFrameForIsVertical:[self isVerticalAnimation]];
    self.animationView = animationView;
    if (_showAnimation) {
        _timeAnimationTimer = [MSWeakTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(changeTimeView) userInfo:nil repeats:YES dispatchQueue:dispatch_get_main_queue()];
    } else {
        animationContainerView.hidden = YES;
    }
    
    if (self.autoCancelTime > 0) {
        _autoCancelTimer = [MSWeakTimer scheduledTimerWithTimeInterval:self.autoCancelTime target:self selector:@selector(autoCancel) userInfo:nil repeats:YES dispatchQueue:dispatch_get_main_queue()];
    }
    [self setupTorch];
}

- (void)setupTorch
{
    NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
    UIImage *unselectedImage = [UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"flash" ofType:@"png"]];
    UIImage *selectedImage = [UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"flash_s" ofType:@"png"]];
    UIButton *btnTorch = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnTorch setTitle:@"torch" forState:UIControlStateNormal];
    [btnTorch setImage:unselectedImage forState:UIControlStateNormal];
    [btnTorch setImage:selectedImage forState:UIControlStateSelected];
    [btnTorch setFrame:CGRectMake(0, 0, 60, 60)];
    CGPoint center = self.view.center;
    center.y = SCREEN_HEIGHT - btnTorch.frame.size.height;
    btnTorch.center = center;
    [btnTorch setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [btnTorch addTarget:self action:@selector(onTorchChange) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnTorch];
    self.btnTorch = btnTorch;
    self.btnTorch.transform = self.interfaceTransform;
    self.btnTorch.hidden = !(([self.capture.captureDevice respondsToSelector:@selector(isTorchAvailable)] && [self.capture.captureDevice isTorchAvailable]) || [UIImagePickerController isFlashAvailableForCameraDevice:UICameraForAVPosition(self.capture.captureDevice.position)]);
}

-(void)setShowAnimation:(BOOL)showAnimation{
    _showAnimation = showAnimation;
    if (!_showAnimation) {
        self.animationContainerView.hidden = YES;
        [_timeAnimationTimer invalidate];
    } else {
        self.animationContainerView.hidden = NO;
        _timeAnimationTimer = [MSWeakTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(changeTimeView) userInfo:nil repeats:YES dispatchQueue:dispatch_get_main_queue()];
    }
}

-(void)setAutoCancelTime:(NSInteger)autoCancelTime{
    if (autoCancelTime > 0) {
        _autoCancelTimer = [MSWeakTimer scheduledTimerWithTimeInterval:autoCancelTime target:self selector:@selector(autoCancel) userInfo:nil repeats:YES dispatchQueue:dispatch_get_main_queue()];
    } else {
        [_autoCancelTimer invalidate];
    }
    _autoCancelTime = autoCancelTime;
}

-(BOOL)isVerticalAnimation{
    return self.captureOrientation != AVCaptureVideoOrientationPortrait;
}

-(void)changeTimeView{
    self.animationView.frame = [self calcRectFrameForIsVertical:[self isVerticalAnimation]];
}

-(CGRect)calcRectFrameForIsVertical:(BOOL)isVertical {
    NSTimeInterval time = CFAbsoluteTimeGetCurrent() - self.animationTime;
    while (time > kAnimationTime) {
        time -= kAnimationTime;
        self.animationTime += kAnimationTime;
    }
    CGRect result = CGRectZero;
    CGFloat halfTime = kAnimationTime / 2.0;
    self.animationContainerView.frame = self.readerView.windowFrame;
    result = self.animationContainerView.bounds;
    if (!isVertical) {
        if (time < halfTime) {
            self.animationView.image =  self.animationImageDown;
            result.size.width = kAnimationWidth;
            result.origin.x = (self.animationContainerView.bounds.size.width + 2 * kAnimationWidth) / halfTime * time - 2 * kAnimationWidth;
        } else {
            time -= halfTime;
            self.animationView.image = self.animationImage;
            result.size.width = kAnimationWidth;
            result.origin.x = self.animationContainerView.bounds.size.width - (self.animationContainerView.bounds.size.width + 3*kAnimationWidth)/ halfTime * time + kAnimationWidth ;
        }
    } else {
        if (time < halfTime) {
            self.animationView.image = self.animationImageLeft;
            result.size.height = kAnimationWidth;
            result.origin.y = (self.animationContainerView.bounds.size.height + 2 * kAnimationWidth) / halfTime * time - 2 * kAnimationWidth;
        } else {
            time -= halfTime;
            self.animationView.image = self.animationImageRight;
            result.size.height = kAnimationWidth;
            result.origin.y = self.animationContainerView.bounds.size.height - (self.animationContainerView.bounds.size.height + 3 * kAnimationWidth) / halfTime * time + kAnimationWidth;
        }
    }
    //    NSLog(@"x--- = %f",result.origin.x);
    return result;
}

-(UIImage *)animationImage{
    if (_animationImage == nil) {
        NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
        UIImage *image = [UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"Group@2x" ofType:@"png"]];
        _animationImage = image;
    }
    return _animationImage;
}

-(UIImage *)animationImageLeft{
    if (_animationImageLeft == nil) {
        NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
        UIImage *image = [UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"Group@2x" ofType:@"png"]];
        _animationImageLeft = [self image:image orientation:UIImageOrientationLeft];
    }
    return _animationImageLeft;
}

-(UIImage *)animationImageRight{
    if (_animationImageRight == nil) {
        NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
        UIImage *image = [UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"Group@2x" ofType:@"png"]];
        _animationImageRight = [self image:image orientation:UIImageOrientationRight];
    }
    return _animationImageRight;
}

-(UIImage *)animationImageDown{
    if (_animationImageDown == nil) {
        NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
        UIImage *image = [UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"Group@2x" ofType:@"png"]];
        _animationImageDown = [self image:image orientation:UIImageOrientationDown];
    }
    return _animationImageDown;
}


-(UIImage*)image:(UIImage*)image orientation:(UIImageOrientation)orientation
{
    UIImage *tempImage = image;
    return [[self class] fixOrientation:tempImage targetOrientation:orientation];
}

+ (UIImage *)fixOrientation:(UIImage *)aImage targetOrientation:(UIImageOrientation)orient;
{
    if (orient == UIImageOrientationUp) {
        return aImage;
    }
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (orient) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (orient) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (orient) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self start];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    if (self.lastRotatedInterfaceOrientation != [[UIApplication sharedApplication] statusBarOrientation]) {
        [self willRotateToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] inDuration:0];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self didCancel];
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无相机授权" message:@"摄像头授权受限，请去\n设置->隐私中修改" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles: nil];
//            [alert show];
//        });
        [self receivedError:1];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stop];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.contentMode = UIViewContentModeScaleAspectFill;
    self.view.clipsToBounds = YES;
    self.view.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;//important for rotate
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.capture.captureSession];
    [self.previewLayer setBackgroundColor:[[UIColor whiteColor] CGColor]];
//    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
//    CGRect bounds = self.view.bounds;
//    bounds.origin = CGPointZero;
//    [self.previewLayer setBounds:bounds];
//    [self.previewLayer setPosition:CGPointMake(bounds.size.width/2.0f, bounds.size.height/2.0f)];
    
    [self.previewLayer setFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    
    [self.view.layer addSublayer:self.previewLayer];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (CHECK_IF_FOCUSED_FIRST && [keyPath isEqualToString:@"adjustingFocus"]) {
        BOOL bAdjustingFocus = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
            self.captureReader.adjustingFocus = bAdjustingFocus;
//        NSLog(@"Is adjusting focus? %@", bAdjustingFocus ? @"YES" : @"NO" );
//        NSLog(@"Change dictionary: %@", change);
    }
}

#pragma mark - rotate methods
//for ios 5.1 below
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        return YES;
    }
    return NO;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
- (BOOL) shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
#endif

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation inDuration:(NSTimeInterval)duration
{
    if (self.readerView) {
        [self.readerView willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
        [self.readerView setNeedsLayout];
    }
    [UIView animateWithDuration:duration animations:^{
        CGFloat  angle = 0;
        CGFloat positionX = self.view.bounds.size.width/2.0f;
        CGFloat positionY = self.view.bounds.size.height/2.0f;
        if ( (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) && UIInterfaceOrientationIsLandscape(toInterfaceOrientation))||
            (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) && UIInterfaceOrientationIsPortrait(toInterfaceOrientation))) {
            positionX = positionX+positionY;
            positionY = positionX-positionY;
            positionX = positionX-positionY;
        }
        switch(toInterfaceOrientation)
        {
            case UIInterfaceOrientationLandscapeLeft:
                angle = M_PI_2;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                angle = M_PI;
                break;
            case UIInterfaceOrientationLandscapeRight:
                angle = 3 * M_PI_2;
                break;
            case UIInterfaceOrientationPortrait:
                angle = 2 * M_PI;
                break;
            default:
                break;
        }
        self.previewLayer.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
        [self.previewLayer setPosition:CGPointMake(positionX, positionY)];
    }];
    [self.previewLayer removeAllAnimations];
    self.lastRotatedInterfaceOrientation = toInterfaceOrientation;
    [self.captureReader setOrientation:toInterfaceOrientation];
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

#pragma mark - inside methods

- (void)changeCaptureMode:(NSInteger)iMode
{
    self.iMode = iMode;
    
    //clean all
    if (self.captureReader) {
        [self.capture removeCaptureOutput:self.captureReader.captureOutput];
    }
    NSArray *arrSubViews = self.view.subviews;
    [arrSubViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.lastRotatedInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
}

- (void)start
{
    if (!self.capture.captureSession.isRunning) {
        [self.capture.captureSession startRunning];
    }
    if (!self.captureReader.delegate) {
        [self.captureReader setDelegate:self];
    }
    if (CHECK_IF_FOCUSED_FIRST) {
        // add auto focus observing
        AVCaptureDevice *camDevice = self.capture.captureDevice;
        [camDevice addObserver:self
                    forKeyPath:@"adjustingFocus"
                       options:NSKeyValueObservingOptionNew
                       context:nil];
    }
    [self.captureReader willStartRunning];

}

- (void)stop
{
    if (self.captureReader.delegate) {
        [self.captureReader setDelegate:nil];
    }
    if (CHECK_IF_FOCUSED_FIRST) {
        @try {
            AVCaptureDevice *camDevice = self.capture.captureDevice;
            [camDevice removeObserver:self
                           forKeyPath:@"adjustingFocus"];
        } @catch (id Exception) {
            // already removed
        }
    }
    [self.captureReader willStopRunning];
    if (self.capture.captureSession.isRunning) {
        [self.capture.captureSession stopRunning];
    }
}

#pragma mark - IBActions
-(void)autoCancel{
    if ([self hasFindCard]) {
        return;
    }
//    [self stop];
    
    if(self.captureDelegate && [self.captureDelegate respondsToSelector:@selector(autoCancel)])
    {
        [self.captureDelegate autoCancel];
        return;
    }
}

-(BOOL)hasFindCard{
    return NO;
}

- (void)didCancel
{
    [self stop];
    
    if(self.captureDelegate && [self.captureDelegate respondsToSelector:@selector(didCancel)])
    {
        [self.captureDelegate didCancel];
        return;
    }
}

- (void)resetAutoCancelTimer{
    if (_autoCancelTime > 0) {
        [_autoCancelTimer invalidate];
        _autoCancelTimer = [MSWeakTimer scheduledTimerWithTimeInterval:_autoCancelTime target:self selector:@selector(autoCancel) userInfo:nil repeats:YES dispatchQueue:dispatch_get_main_queue()];
    }
}

- (void)changeScanDirection:(UIButton *)button{
    [self stop];
    [self start];
    if(self.captureDelegate && [self.captureDelegate respondsToSelector:@selector(changeScanDirection:)])
    {
        [self.captureDelegate changeScanDirection:button];
    }
}

- (void)onTorchChange
{
    if (([self.capture.captureDevice respondsToSelector:@selector(isTorchAvailable)] && [self.capture.captureDevice isTorchAvailable]) || [UIImagePickerController isFlashAvailableForCameraDevice:UICameraForAVPosition(self.capture.captureDevice.position)]) {
        self.autoTorch = YES;
        switch (self.capture.torchMode) {
            case AVCaptureTorchModeOff:
                [self.capture setTorchMode:AVCaptureTorchModeOn];
                [self.btnTorch setSelected:YES];
                break;
            case AVCaptureTorchModeOn:
                [self.capture setTorchMode:AVCaptureTorchModeOff];
                [self.btnTorch setSelected:NO];
                break;
            default:
                break;
        }
    } else {
//        [[ToastViewAlert defaultCenter] postAlertWithMessage:@"您的设备无法打开闪光灯"];
    }
}

- (void)onFrontCameraChange
{
    switch (self.capture.captureDevice.position) {
        case AVCaptureDevicePositionUnspecified:
        case AVCaptureDevicePositionBack:
            [self.capture setDevicePosition:AVCaptureDevicePositionFront];
            [self.btnFrontCamera setSelected:YES];
            break;
        case AVCaptureDevicePositionFront:
            [self.capture setDevicePosition:AVCaptureDevicePositionBack];
            [self.btnFrontCamera setSelected:NO];
            break;
        default:
            break;
    }
}

#pragma mark - WCCCaptureReaderDelegate 

// need reconsitution
- (void)captureReader:(LFCaptureReader *)reader didSnapshot:(UIImage *)image
{
    [self stop];
}

- (void)captureReader:(LFCaptureReader *)reader didSnapshotInProgress:(UIImage *)image
{
    if([self.captureDelegate respondsToSelector:@selector(getSnapshot:)]) {
        [self.captureDelegate getSnapshot:image];
    }
}

- (void)captureReader:(LFCaptureReader *)reader didCancel:(NSString *)strMessage
{
    if ( strMessage.length > 0  ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] ;
        [alert show] ; 
    }
    [self didCancel];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.capture.torchMode == AVCaptureTorchModeOff && !self.autoTorch) {
        CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
        CFRelease(metadataDict);
        NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
        float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
        // brightnessValue 值代表光线强度，值越小代表光线越暗
        if (brightnessValue <= -2) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self onTorchChange];
            });
        }
    }
}

- (void)receivedErrorNote:(NSNotification *)notification {
    NSInteger code = [(NSNumber *)[notification object] integerValue];
    [self receivedError:code];
}

#pragma mark - UI modification
// The interface to modify the line color.
- (void)setTheScanLineColor:(UIColor *)color {
    if (_readerView) {
        [self.readerView setLineColor:color];
    }
    _lineColor = color;
}
// The interface to modify the layer color.
- (void)setTheMaskLayerColor:(UIColor *)color andAlpha:(CGFloat)alpha{
    if (_readerView) {
        [self.readerView setMaskLayerColor:color andAlpha:alpha];
    }
    self.maskColor = color;
    self.maskAlpha = alpha;
}

- (void)setTheScanLineAndLayerColor{
    if(self.lineColor){
        [self.readerView setLineColor:self.lineColor];
    }
    if (self.maskColor) {
        [self.readerView setMaskLayerColor:self.maskColor andAlpha:self.maskAlpha];
    }
}

- (void)receivedError: (NSInteger)errorCode{
    
}
@end
