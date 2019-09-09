//
//  LFCapturePhotoViewController.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFCapturePhotoViewController.h"
#import "LFBankCardMaskView.h"
#import "LFCaptureDelegate.h"
#import <OCR_SDK/OCR_SDK.h>
#import <Photos/PHPhotoLibrary.h>
#import "SVProgressHUD.h"

#define KMaxReserved 70
#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)

@interface LFCapturePhotoViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign) BOOL isFront;
//硬件设备
@property (nonatomic, strong) AVCaptureDevice *device;
//输入流
@property (nonatomic, strong) AVCaptureDeviceInput *input;
//协调输入输出流的数据
@property (nonatomic, strong) AVCaptureSession *session;
//原始视频帧，用于获取实时图像以及视频录制
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;  //用于捕捉静态图片

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer; //预览层

@property (nonatomic, strong) UIButton *btnCancel;

@property (nonatomic, strong) UIButton *photoButton;

@property (nonatomic, weak) UIView *preview;

@property (nonatomic, assign) UIInterfaceOrientation orientation;

@end

@implementation LFCapturePhotoViewController

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
                _btnCancel.frame = CGRectMake(SCREEN_WIDTH - 40 - 22, 20, 40, 40);
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

- (UIButton *)photoButton {
    if (!_photoButton) {
        _photoButton = [[UIButton alloc] init];
        _photoButton.frame = CGRectMake(SCREEN_WIDTH - 60 - 22, LFStatusBarHeight, 60, 40);
        [_photoButton setTitle:@" 相册" forState:UIControlStateNormal];
        [_photoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_photoButton setBackgroundColor:[UIColor clearColor]];
        [_photoButton addTarget:self action:@selector(photoButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _photoButton;
}

- (instancetype)initWithLicensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard {
    return [self initWithLicenesePath:licensePath shouldFullCard:shouldFullCard modelPath:nil extraPath:nil];
}

- (instancetype)initWithLicenesePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard modelPath:(NSString *)modelPath extraPath:(NSString *)extraPath {
    LFCapturePhotoViewController *vc = [[LFCapturePhotoViewController alloc] init];
    return vc;
}

- (void)setIsScanVerticalCard:(BOOL)isScanVerticalCard {
    _isScanVerticalCard = isScanVerticalCard;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    [self setupDirection];
    [self setupNavigationBar];
    [self setupSubViews];
}

-(void)dealloc{
    @synchronized (self) {
        [self stopScanning];
    }
}

- (void)setupDirection {
    self.captureOrientation = AVCaptureVideoOrientationPortrait;
    
    switch (self.captureOrientation) {
        case AVCaptureVideoOrientationPortrait:
        {
            self.orientation = UIInterfaceOrientationPortrait;
        }
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
        {
            self.orientation = UIInterfaceOrientationLandscapeLeft;
        }
            break;
        case AVCaptureVideoOrientationLandscapeRight:
        {
            self.orientation = UIInterfaceOrientationLandscapeRight;
        }
            break;
        default:
        {
            self.orientation = UIInterfaceOrientationPortrait;
        }
            break;
    }
    
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
}

- (void)didCancel {
    
}

- (void)photoButtonClick {
    
    [self showPickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self startScanning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavigationBar
{
    self.title = @"扫描";
}

-(void)setupSubViews{
    
    UIView *preview = [[UIView alloc] init];
    preview.clipsToBounds = YES;
    [self.view addSubview:preview];
    preview.frame = self.view.frame;
    [preview.layer addSublayer:self.previewLayer];
    self.preview = preview;
    
    CGRect bounds = self.view.layer.bounds;
    bounds = CGRectMake(0, 0 , bounds.size.width, bounds.size.height);
    self.previewLayer.bounds = bounds;
    self.previewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    LFBankCardMaskView *readerView = [[LFBankCardMaskView alloc] initWithFrame:self.view.bounds andWindowFrame:CGRectZero Orientation:self.orientation];
    [self.view addSubview:readerView];
    self.readerView = readerView;
    [self.readerView changeScanWindowDirection:self.isScanVerticalCard];
    
    [self.view addSubview:self.btnCancel];
    
    UIView *takeView = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH *0.5 - 50, SCREEN_HEIGHT - 105 - LFTabbarSafeBottomMargin, 100, 100)];
    takeView.layer.cornerRadius = 50;
    takeView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    [self.view addSubview:takeView];

    UIButton *takePictureButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH *0.5 - 40, SCREEN_HEIGHT - 95 - LFTabbarSafeBottomMargin, 80, 80)];
    takePictureButton.backgroundColor = [UIColor orangeColor];
    takePictureButton.layer.cornerRadius = 40;
    [takePictureButton setTitle:@"拍摄" forState:UIControlStateNormal];
    [takePictureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [takePictureButton addTarget:self action:@selector(screenshot:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takePictureButton];
    
    [self.view addSubview:self.photoButton];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //设置图像方向，否则largeImage取出来是反的
    //    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    //    UIImage *originImage = [self imageFromSampleBuffer:sampleBuffer];
    //    UIImage *largeImage = [UIImage fixOrientation:originImage];
}

//CMSampleBufferRef转NSImage
-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    // 释放context和颜色空间
    CGContextRelease(context); CGColorSpaceRelease(colorSpace);
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationUpMirrored];
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    return (image);
}

#pragma mark - Video member


- (AVCaptureVideoPreviewLayer *)previewLayer{
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}

-(AVCaptureDevice *)device{
    if (_device == nil) {
        _device = [self cameraWithPosition:_isFront ? AVCaptureDevicePositionFront:AVCaptureDevicePositionBack];
        if ([_device lockForConfiguration:nil]) {
            //自动闪光灯
            if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
                [_device setFlashMode:AVCaptureFlashModeAuto];
            }
            //自动白平衡
            if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
            }
            //自动对焦
            if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [_device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            //自动曝光
            if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [_device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            
            int frameRate = 30;
            CMTime frameDuration = kCMTimeInvalid;
            frameDuration = CMTimeMake(1, frameRate);
            _device.activeVideoMaxFrameDuration = frameDuration;
            _device.activeVideoMinFrameDuration = frameDuration;
            
            [_device unlockForConfiguration];
        }
    }
    return _device;
}


-(AVCaptureDeviceInput *)input{
    if (_input == nil) {
        _input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    }
    return _input;
}

-(AVCaptureStillImageOutput *)stillImageOutput{
    if (_stillImageOutput == nil) {
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    return _stillImageOutput;
}

-(AVCaptureVideoDataOutput *)videoDataOutput{
    if (_videoDataOutput == nil) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        //设置像素格式，否则CMSampleBufferRef转换NSImage的时候CGContextRef初始化会出问题
        [_videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    }
    return _videoDataOutput;
}

-(AVCaptureSession *)session{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
        
        [_session beginConfiguration];
        
        if ([_session canAddInput:self.input]) {
            [_session addInput:self.input];
        }
        if ([_session canAddOutput:self.stillImageOutput]) {
            [_session addOutput:self.stillImageOutput];
        }
        if ([_session canAddOutput:self.videoDataOutput]) {
            [_session addOutput:self.videoDataOutput];
        }
        if ([_session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            _session.sessionPreset = AVCaptureSessionPreset1280x720;
        }
        AVCaptureConnection *connection = self.videoDataOutput.connections.firstObject;
        if (connection) {
            connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
        [_session commitConfiguration];
    }
    return _session;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
}

- (void)screenshot:(UIButton *)sender {
    
    sender.enabled = NO;
    
    AVCaptureConnection * videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSLog(@"take photo failed!");
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
        UIImage *cropedImage = [weakSelf fixOrientation:image];
        NSLog(@"%@",cropedImage);
        
        CGRect newRect = [LFCapturePhotoViewController transformRect:self.readerView.windowFrame fromRect:self.view.frame toRect:CGRectMake(0, 0, cropedImage.size.width, cropedImage.size.height) captureOrientation:self.captureOrientation];
        UIImage *newImage = [self imageFromImage:cropedImage inRect:newRect];
        [weakSelf handleImage:newImage];
        sender.enabled = YES;
    }];
}

+ (CGRect)transformRect:(CGRect)oriRect fromRect:(CGRect)fromRect toRect:(CGRect)toRect captureOrientation:(AVCaptureVideoOrientation)captureOrientation {
    
    // 获取的边框处理
    CGFloat newHeight = (oriRect.size.height / fromRect.size.height * toRect.size.height);
    CGFloat newWidth = (oriRect.size.width / oriRect.size.height * newHeight);
    
    CGFloat reserved = 0.0;
    CGFloat reservedHeight = 0.0;
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    
    if (captureOrientation == AVCaptureVideoOrientationPortrait) {
        
        reserved = (toRect.size.width - newWidth) *0.8;
        reserved = reserved > KMaxReserved ? KMaxReserved : reserved;
        reservedHeight = newHeight / newWidth * reserved;
        
        x = round((toRect.size.width - newWidth - reserved) / 2.0);
        y = round(((oriRect.origin.y - fromRect.origin.y) *( toRect.size.height / fromRect.size.height)) - (reservedHeight *0.5));

    } else if ((captureOrientation == AVCaptureVideoOrientationLandscapeLeft || captureOrientation == AVCaptureVideoOrientationLandscapeRight)) {
        
        reservedHeight = (toRect.size.height - newHeight) *0.8;
        reservedHeight = reservedHeight > KMaxReserved ? KMaxReserved : reservedHeight;
        reserved = newWidth / newHeight * reservedHeight;
        
        x = round((toRect.size.height - newWidth - reserved) / 2.0);
        y = round((toRect.size.width - newHeight - reservedHeight) / 2.0);
    }
    
    newWidth = newWidth + reserved > toRect.size.width ? toRect.size.width : newWidth + reserved;
    newHeight = newHeight + reservedHeight > toRect.size.height ? toRect.size.height : newHeight + reservedHeight;

    return CGRectMake((CGFloat)(fabs(x)), (CGFloat)(fabs(y)), round(newWidth), round(newHeight));
}

//截取图片大小
- (UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect {
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage;
}

- (void)handleImage:(UIImage *)image {

}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    return [self fixOrientation:aImage targetOrientation:aImage.imageOrientation];
}

- (UIImage *)fixOrientation:(UIImage *)aImage targetOrientation:(UIImageOrientation)orient;
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

-(void)startScanning{
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
}

-(void)stopScanning{
    if (_session.isRunning) {
        [_session stopRunning];
    }
}

- (void)showPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{

}

@end
