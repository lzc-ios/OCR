//
//  LFIDCardReader.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <libkern/OSAtomic.h>
#import "LFIDCardReader.h"
#import <OCR_SDK/OCR_SDK.h>
#import <Endian.h>

#define MAX_Attributes 32
#define kCountTimeOutDefault  1200
#define ST_MAX_RECOGNIZE_THREAD 1    // For Multi-Core Accelerate

enum {
    PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
    PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
    PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
    PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
    PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
    PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
    PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
    PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
};

@interface LFIDCardReader ()
{
    int _iMoveDelta ; //  iDelta == 0 in center , > 0 move up, < 0 move down
    int _iMoveDeltaCopy ; //  copy on each frame, for thread-safe on frame processing
    
    LFIDCardMode _tempCardMode;
    NSDate *_lastsnapshotTime;
}

@property (nonatomic, strong) NSMutableArray *availableIDCards;

@property (nonatomic, assign) bool  bNeedChangeCardMode;


@end

@implementation LFIDCardReader

//@synthesize strPlate ;
@synthesize maskView ;

- (instancetype)initWithLicenseName:(NSString *)licenseName shouldFullCard:(BOOL)shouldFullCard
{
    self = [self initWithLicensePath:[[NSBundle mainBundle] pathForResource:licenseName ofType:@"lic"] shouldFullCard:shouldFullCard];
    self.licenseName = licenseName;
    return self;
}

- (instancetype)initWithLicensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard {
    return [self initWithLicensePath:licensePath shouldFullCard:shouldFullCard modelPath:nil];
}

- (instancetype)initWithLicensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard modelPath:(NSString *)modelPath {
    
    self = [super initWithLicensePath:licensePath];
    if (self) {
        //set captureOutput property
        self.captureOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        self.adjustingFocus = NO;
        
        self.snapshotSeconds = -1;
        _lastsnapshotTime = nil;
         if ( self.bDebug )
            NSLog( @"LFIDCardReader init, LFIDCardScannerController init. " );
        
        _availableIDCards = [[NSMutableArray alloc] init] ;
        for (int i = 0; i < MIN(ST_MAX_RECOGNIZE_THREAD, [[NSProcessInfo processInfo] activeProcessorCount]); i++) {
            LFIDCard *idcard = [[LFIDCard alloc] initWithModelPath:@"ocr_card" extraPath:nil];
            if (idcard) {
                idcard.shouldFullCard = shouldFullCard;
                idcard.bDebug = self.bDebug;
                idcard.iMode = kIDCardSmart;
                [_availableIDCards addObject:idcard];
            }
        }
        //        NSLog( @"LFIDCard init version = %@ ", LFIDCard.strVersion );
        self.bProcessEnabled = YES ; // perform OCR on each video frame
    }
    return self;
}

- (void) setBDebug:(BOOL)bDebug
{
    _bDebug = bDebug ;
    for (LFIDCard *idcard in self.availableIDCards) {
        idcard.bDebug = bDebug;
    }
}

- (void)setMode:(LFIDCardMode)mode
{
    UILabel *tempLabel = [[UILabel alloc] init];
    tempLabel.textColor = [UIColor whiteColor];
    [self loopSetIDCardMode:mode];
    switch (mode) {
        case kIDCardSmart:
            tempLabel.text = @"请将身份证放入扫描框内";
            [self.maskView setLabel:tempLabel];
            break;
        case kIDCardFrontal:
            tempLabel.text = @"请将身份证正面放入扫描框内";
            [self.maskView setLabel:tempLabel];
            break;
        case kIDCardBack:
            tempLabel.text = @"请将身份证反面放入扫描框内";
            [self.maskView setLabel:tempLabel];
            break;

        default:
            break;
    }
}

- (void)loopSetIDCardMode:(LFIDCardMode)mode{
    self.bNeedChangeCardMode = YES;
    if ([self.availableIDCards count] > 0) {
        for (LFIDCard *idcard in self.availableIDCards) {
            idcard.iMode = mode;
        }
        self.bNeedChangeCardMode = NO;
    }else{
        _tempCardMode = mode;
    }
    
}

- (void)setHintLabel:(UILabel *)label{
    [self.maskView setLabel:label];
}


- (void) dealloc
{
    if ( self.bDebug )
        NSLog( @"LFIDCardReader dealloc." );
}

- (void)recognizeWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    if ( !self.bProcessEnabled )
        return ;

    if (self.adjustingFocus){
        return;
    }

    // 没取到结果前，拍快照
//    [self snapshot:sampleBuffer];

    if (!CMSampleBufferIsValid(sampleBuffer)) {
        return;
    }
    if ([self.availableIDCards count] <= 0) {
        return;
    }
    LFIDCard *idcard = [self.availableIDCards lastObject];
    [self.availableIDCards removeObject:idcard];
    CFRetain(sampleBuffer);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
        _iMoveDeltaCopy = _iMoveDelta ;
        
//        UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
//        UIImage *test = [self cropImage:image atRect:self.recWindow];
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        uint8_t *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        uint8_t *window_buffer = [self transformRGBAtoRGB:baseAddress width:width height:height];
        CGRect rectW = self.recWindow;
        int realWidth  = rectW.size.width;
        int realHeight = rectW.size.height;
//        [idcard recognizeCardWithBuffer:pixelBuffer];
        idcard.appID = self.appID;
        idcard.appSecret = self.appSecret;
        idcard.isVertical = self.isVertical;
        idcard.isAuto = self.isAuto;
        idcard.returnType = self.returnType;
        uint8_t *out_image = (uint8_t *)malloc(realWidth * realHeight *4);
        RGB2GrayAverage(realHeight * realWidth, window_buffer,out_image);
    
        int iResult = 0;
       
        @synchronized (self) {
            iResult = [idcard recognizeCardWithBuffer:window_buffer width:realWidth height:realHeight];
        }
        if ( iResult == 2 ) {
            UIImage * image2 = [self imageFromCharRef:window_buffer withWidth:realWidth andHeight:realHeight];
            UIImage *fullImage = [self imageFromSampleBuffer:sampleBuffer];
            [idcard setImgOriginCaptured:fullImage];
            [idcard setImgOriginCroped:image2];

            dispatch_sync(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(captureReader:getCardResult:)]) {
                 
                    [self.delegate captureReader:self getCardResult:idcard];
                }
            });
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
    
        [self activeIDCardInAvailableBankCards:idcard];
//        // 释放资源
        free(window_buffer);
        CFRelease(sampleBuffer);
        free(out_image);
    });


    return ;
    
}



#pragma mark - 图片转灰阶
void cv_finance_idcard_rgb_2_gray(unsigned char *src,unsigned char *dest,int width,int height)
{
    int r = 0, g =0 , b = 0;
    for (int i=0;i<width*height;++i)
    {
        r = *src++; // load red
        g = *src++; // load green
        b = *src++; // load blue
        // build weighted average:
        *dest++ = (r * 76 + g * 150 + b * 30) >> 8;
    }
}

void RGB2GrayAverage(int sizeOfPixel, unsigned char *imageData,unsigned char *gray){
    for (int i = 0; i < sizeOfPixel; i++)
    {
        unsigned char r = imageData[ i + 0];
       unsigned char g = imageData[i + 1];
        unsigned char b = imageData[i + 2];
        *gray++ = (b + g + r)/3;
    }
}


- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize

{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return reSizeImage;
    
}
- (UIImage *)imageFromCharRef:(unsigned char *)buffer withWidth:(int)iWidth andHeight:(int)iHeight {
    
    double t0 = CFAbsoluteTimeGetCurrent();
    unsigned char *_pCardImageBufferRGBA = NULL;
    unsigned char *pRGBBuffer = buffer ;
    if ( _pCardImageBufferRGBA != NULL ) {
        free (_pCardImageBufferRGBA) ;
        _pCardImageBufferRGBA = NULL ;
    }
    _pCardImageBufferRGBA = (unsigned char *) malloc( iWidth * iHeight * 4);
    long indexRGB = 0 ;
    long indexRGBA = 0 ;
    for ( int y = 0 ; y < iHeight ; y++ ) {
        for (int x = 0 ; x < iWidth ; x++ ) {
            _pCardImageBufferRGBA[indexRGBA++]= pRGBBuffer[indexRGB++ + 2] ;
            _pCardImageBufferRGBA[indexRGBA++]= pRGBBuffer[indexRGB++] ;
            _pCardImageBufferRGBA[indexRGBA++]= pRGBBuffer[indexRGB++ - 2] ;
            _pCardImageBufferRGBA[indexRGBA++]= 255 ; // skip Alpha Channel, not transparent
        }
    }
    
    //    buffer = _pCardImageBufferRGBA ;
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(_pCardImageBufferRGBA, iWidth, iHeight, 8,
                                                 iWidth * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    // Create an image object from the Quartz image
    UIImage *ret = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(_pCardImageBufferRGBA);
    _pCardImageBufferRGBA = NULL;
    double t1 = CFAbsoluteTimeGetCurrent();
    if ( self.bDebug )
        NSLog(@"RGB->RGBA: %f", t1 - t0);
    
    return ret;
}


- (UIImage *)cropImage:(UIImage *)image atRect:(CGRect) rect
{
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect drawRect = CGRectMake(-rect.origin.x, -rect.origin.y, image.size.width, image.size.height);
    CGContextClipToRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
    [image drawInRect:drawRect];
    UIImage* croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return croppedImage;
}
//方法1 此方法能还原真实的图片
- (CVPixelBufferRef)pixelBufferFromCGImage: (CGImageRef) image
{
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
                              };
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
-(void)snapshot:(CMSampleBufferRef)sampleBuffer{
    if (self.snapshotSeconds <= 0) return;
    if (_lastsnapshotTime == nil) {
        _lastsnapshotTime = [NSDate date];
    }
    NSDate *cur = [NSDate date];
    double deltaTime = [cur timeIntervalSinceDate:_lastsnapshotTime];
    if (deltaTime >= self.snapshotSeconds) {
        _lastsnapshotTime = cur;
        if ([self.delegate respondsToSelector:@selector(captureReader:didSnapshotInProgress:)]) {
            UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
            [self.delegate captureReader:self didSnapshotInProgress:image];
        }
    }
}

- (uint8_t*)transformRGBAtoRGB:(uint8_t*)baseAddress width:(int)width height:(int)height{
    size_t buffer_size = sizeof(unsigned char) * self.recWindow.size.width * self.recWindow.size.height * PIXEL_COMPONENT_NUM;
    uint8_t *window_buffer = malloc(buffer_size);
    int dn = 0;
    int on = 0;
    CGRect rectW = self.recWindow;
    for (int y=0; y < height; y++) {
        for (int x = 0; x< width; x++) {
            if (dn >= buffer_size) {
                break;
            }
            if (y>=(int)rectW.origin.y && y < (int)(rectW.origin.y + rectW.size.height) && x>=(int)rectW.origin.x && x< (int)(rectW.origin.x + rectW.size.width)) {
                window_buffer[dn++] = baseAddress[on++]; // R
                window_buffer[dn++] = baseAddress[on++]; // G
                window_buffer[dn++] = baseAddress[on++]; // B
                on++; // skip alph
            } else {
                on += 4;
            }
        }
        if (dn >= buffer_size) {
            break;
        }
    }
    return window_buffer;
}

- (void)activeIDCardInAvailableBankCards:(id)Object{
    [self.availableIDCards addObject:Object];
    if (self.bNeedChangeCardMode == YES && self.availableIDCards.count > 0) {
        [self loopSetIDCardMode:_tempCardMode];
    }
}

- (void)moveWindowVerticalFromCenterWithDelta:(int) iDelta   //  iDeltaY == 0 in center , < 0 move up, > 0 move down
{
    if (!(self.orientation == AVCaptureVideoOrientationPortrait)) {
        return;
    }
    _iMoveDelta = iDelta;
    
    CGFloat realHeight = SCREEN_HEIGHT;
    
    if ((self.recWindow.origin.y + (CGFloat)_iMoveDelta / realHeight * (CGFloat)self.iVideoHeight) <0) {
        _iMoveDelta = 0 - self.recWindow.origin.y / (CGFloat)self.iVideoHeight * realHeight;
    }
    if ((self.recWindow.origin.y + (CGFloat)_iMoveDelta / realHeight * (CGFloat)self.iVideoHeight + self.recWindow.size.height > (CGFloat)self.iVideoHeight)) {
        _iMoveDelta = realHeight - self.recWindow.origin.y / (CGFloat)self.iVideoHeight * realHeight - self.recWindow.size.height / self.iVideoHeight * realHeight;
    }
    CGRect tmpRect = self.recWindow;
    if (self.iVideoHeight > self.iVideoWidth) {
        tmpRect.origin.y += (CGFloat)_iMoveDelta / realHeight * (CGFloat)self.iVideoHeight;
    }
    self.recWindow = tmpRect;

    [self.maskView moveWindowDeltaY:_iMoveDelta] ;

}

- (void)setVideoOrientation:(AVCaptureVideoOrientation)orientation{
    [super setVideoOrientation:orientation];
}

- (void)setRecognizeItemOption:(LFIDCardItemOption)option {
//    for (LFIDCard *card in _availableIDCards) {
//        [card setRecognizeItemsOptions:option];
//    }
}

@end


