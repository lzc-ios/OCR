//
//  LFCaptureReader.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <sys/utsname.h>

#import "LFCommon.h"
#import "LFCaptureReader.h"

#define KMaxReserved 70

@interface LFCaptureReader ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    dispatch_queue_t queue;
    NSFileManager *fileManager;
    int _fileName;
    int _dropNum;
}
@property (nonatomic, assign) BOOL enableReader;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;

@property (nonatomic, assign) CGRect recognizeRect;
@property (nonatomic, assign) CGRect fullRect;


@end

@implementation LFCaptureReader
@synthesize captureOutput = _captureOutput;
@synthesize delegate = _delegate;
@synthesize orientation = _orientation;
@synthesize fScale = _fScale;
@synthesize isAutoFocusSupport = _isAutoFocusSupport;


#pragma mark - getter & setter
- (BOOL)enableReader
{
    return (OSAtomicOr32Barrier(0, &state)&RUNNING);
}

- (void)setEnableReader:(BOOL)enableReader
{
    if (!enableReader) {
        OSAtomicOr32Barrier(STOPPED, &state);
    }else if (!(OSAtomicOr32Barrier(RUNNING, &state)&RUNNING)){
        OSAtomicOr32Barrier(~PAUSED, &state);
    }
}

#pragma mark - life cycle
- (instancetype)initWithLicenseName:(NSString *)licenseName
{
    self = [self initWithLicensePath:[[NSBundle mainBundle] pathForResource:licenseName ofType:@"lic"]];
    self.licenseName = licenseName;
    return self;
}

- (instancetype)initWithLicensePath:(NSString *)licensePath {
    
    self = [super init];
    if (self) {
        self.licensePath = licensePath;
        //create AVCaptureVideoDataOutput
        self.captureOutput = [[AVCaptureVideoDataOutput alloc] init];
        //config the AVCaptureVideoDataOutput
        self.recWindow = CGRectMake(0, 400, 720, 480);
        self.captureOutput.alwaysDiscardsLateVideoFrames = YES;
        self.captureOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        //create GCD queue
        queue = dispatch_queue_create("BarCaptureReader", NULL);
        [self.captureOutput setSampleBufferDelegate:self queue:queue];
        self.fScale = 1.0f;
        channel = 0;
    }
    return self;
}

- (void)dealloc
{
    [self.captureOutput setSampleBufferDelegate:nil queue:queue];
//    dispatch_release(queue);
}

#pragma mark - public methods
- (void)setVideoOrientation:(AVCaptureVideoOrientation)orientation {
    [[self.captureOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:orientation];
    self.captureVideoOrientation = orientation;
    if (CAPTURE_SESSION_QUALITY > 1) {
        self.iVideoWidth = 720;
        self.iVideoHeight = 1280;
    }
    if (orientation == AVCaptureVideoOrientationLandscapeLeft || orientation == AVCaptureVideoOrientationLandscapeRight)  {
        CGRect windowRect = CGRectMake(self.recognizeRect.origin.y, self.recognizeRect.origin.x, self.recognizeRect.size.height, self.recognizeRect.size.width);
        self.recWindow = [self transformRect:windowRect fromRect:self.fullRect toRect:CGRectMake(0, 0, _iVideoWidth, _iVideoHeight)];
    } else {
        self.recWindow = [self transformRect:self.recognizeRect fromRect:self.fullRect toRect:CGRectMake(0, 0, _iVideoWidth, _iVideoHeight)];
    }
}

- (void)setRecognizeRect:(CGRect)recognizeRect inFullRect:(CGRect)fullRect {
    self.recognizeRect = recognizeRect;
    self.fullRect = fullRect;
}

- (CGRect)transformRect:(CGRect)oriRect fromRect:(CGRect)fromRect toRect:(CGRect)toRect {
    
    // 获取的边框处理
//    CGFloat newHeight = (oriRect.size.height / fromRect.size.height * toRect.size.height);
    CGFloat newWidth = (oriRect.size.width / fromRect.size.width * toRect.size.width);
//    CGFloat newWidth = (oriRect.size.width / oriRect.size.height * newHeight);
    CGFloat newHeight = (oriRect.size.height / oriRect.size.width * newWidth);

    CGFloat reserved = 0.0;
    CGFloat reservedHeight = 0.0;
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    
    if (self.captureVideoOrientation == AVCaptureVideoOrientationPortrait) {
        
        reserved = (toRect.size.width - newWidth) *0.8;
        reserved = reserved * (fromRect.size.width / newWidth) > KMaxReserved ? KMaxReserved * (newWidth / fromRect.size.width) : reserved;
        reservedHeight = newHeight / newWidth * reserved;
        
        x = round((toRect.size.width - newWidth - reserved) / 2.0);
        y = round((toRect.size.height - newHeight - reservedHeight) / 2.0);

    } else if ((self.captureVideoOrientation == AVCaptureVideoOrientationLandscapeLeft || self.captureVideoOrientation == AVCaptureVideoOrientationLandscapeRight)) {
        
        reservedHeight = (toRect.size.height - newHeight) *0.8;
        reservedHeight = reservedHeight * (fromRect.size.height / newHeight) > KMaxReserved ? KMaxReserved * (newHeight / fromRect.size.height) : reservedHeight;
        reserved = newWidth / newHeight * reservedHeight;
        
        x = round((toRect.size.height - newWidth - reserved) / 2.0);
        y = round((toRect.size.width - newHeight - reservedHeight) / 2.0);
    }

    return CGRectMake((CGFloat)(fabs(x)), (CGFloat)(fabs(y)),round(newWidth + reserved), round(newHeight + reservedHeight));
}

- (CGRect)getMaskFrame {
    if (self.captureVideoOrientation == AVCaptureVideoOrientationPortrait) {
        return MASK_WINDOW_H;
    } else {
        return MASK_WINDOW_V;
    }
}

- (void)willStartRunning
{
    self.enableReader = YES;
}

- (void)willStopRunning
{
    self.enableReader = NO;
}

- (void)recognizeWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
}

-(void)setRecWindow:(CGRect)recWindow{
    _recWindow = recWindow;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    uint32_t _state = OSAtomicOr32Barrier(0, &state);
    if ((_state & (PAUSED | RUNNING)) != RUNNING) {
        return;
    }
    @autoreleasepool {
        @try {
            [self recognizeWithSampleBuffer:sampleBuffer];
            
            if ([self.delegate respondsToSelector:@selector(captureOutput:didOutputSampleBuffer:fromConnection:)]) {
                [self.delegate captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
            }

        } @catch ( NSException  *e) {
            if ( [self.delegate respondsToSelector:@selector(scannerException:)] ) {
                [self.delegate scannerException:e] ;
            }
        }
    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
//    NSLog(@"_Drop Number:%d",_dropNum);
}

- (UIImage *)rotateImage:(UIImage *)image
{
    CGSize imgSize = [image size];
    CGSize newSize=CGSizeMake(imgSize.height, imgSize.width);
    UIGraphicsBeginImageContext(newSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextRotateCTM(context, M_PI_2);
    CGContextTranslateCTM(context, 0, -imgSize.height);
    [image drawInRect:CGRectMake(0, 0, imgSize.width, imgSize.height)];
    UIImage *newImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage ;
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    /* CVBufferRelease(imageBuffer); */  // do not call this!
    UIImage *resultImage = [UIImage imageWithCGImage:newImage];
    CGImageRelease(newImage);
    return resultImage;
}
@end
