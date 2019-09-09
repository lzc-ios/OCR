//
//  LFBankCardCaputreReader.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFBankCardReader.h"


#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <libkern/OSAtomic.h>
#import <OCR_SDK/OCR_SDK.h>
#import <Endian.h>

#define MAX_Attributes 32
#define ST_MAX_RECOGNIZE_THREAD 1    // For Multi-Core Accelerate

#define SCAN_BOUNDARY 64

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

@interface LFBankCardDoubleChecker : NSObject

- (BOOL)doubleCheck:(LFBankCard *)bankCard;

@end

@interface LFBankCardReader ()
{
    size_t buffer_size;
    
    int         _iMoveDelta ; //  iDelta == 0 in center , > 0 move up, < 0 move down
    int         _iMoveDeltaCopy ; //  copy on each frame, for thread-safe on frame processing
    
    CGRect _tempCardWindowForKVO;
    NSDate *_lastsnapshotTime;
}

@property (nonatomic, strong) NSMutableArray *availableBankCards;

@property (nonatomic, assign) bool  bNeedChangeFrame;


@end

@implementation LFBankCardReader

//@synthesize strPlate ;
@synthesize maskView ;

#pragma mark - Life Cycle
- (instancetype)initWithLicenseName:(NSString *)licenseName shouldFullCard:(BOOL)shouldFullCard
{
    self = [self initWithLicensePath:[[NSBundle mainBundle] pathForResource:licenseName ofType:@"lic"] shouldFullCard:shouldFullCard];
    self.licenseName = licenseName;
    return self;
}

- (instancetype)initWithLicensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard {
    
    return [self initWithLicenesePath:licensePath shouldFullCard:shouldFullCard modelPath:nil extraPath:nil];
}

- (instancetype)initWithLicenesePath:(NSString *)licenesePath shouldFullCard:(BOOL)shouldFullCard modelPath:(NSString *)modelPath extraPath:(NSString *)extraPath
{
    self = [super initWithLicensePath:licenesePath];
    if (self) {
        //set captureOutput property
        self.captureOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        self.adjustingFocus = NO;
        
        self.snapshotSeconds = -1;
        _lastsnapshotTime = nil;
        buffer_size = sizeof(unsigned char) * self.recWindow.size.width * self.recWindow.size.height * PIXEL_COMPONENT_NUM;

        if ( self.bDebug ) {
            NSLog( @"LFIDCardReader init, LFBankCardScannerController init. " );
        }
        
        _availableBankCards = [[NSMutableArray alloc] init] ;
        for (int i = 0; i < MIN(ST_MAX_RECOGNIZE_THREAD, [[NSProcessInfo processInfo] activeProcessorCount]); i++) {

            LFBankCard *bankcard = [[LFBankCard alloc] initWithModelPath:modelPath extraPath:extraPath];
            if (bankcard) {
                bankcard.shouldFullCard = shouldFullCard;
                // Debug;
                bankcard.bDebug = self.bDebug;
                [_availableBankCards addObject:bankcard];
            }
        }
        self.bProcessEnabled = YES ; // perform OCR on each video frame
    }
    return self;
}

- (void) dealloc
{
    if ( self.bDebug )
        NSLog( @"LFIDCardReader dealloc." );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void) setBDebug:(BOOL)bDebug
{
    _bDebug = bDebug ;
    for (LFBankCard *bankcard in self.availableBankCards) {
        bankcard.bDebug = bDebug;
    }
}

- (void)recognizeWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if ( !self.bProcessEnabled )
        return ;
    
    if (self.adjustingFocus) return;
    
    if (self.snapshotSeconds > 0) {
        if (_lastsnapshotTime == nil) {
            _lastsnapshotTime = [NSDate date];
        } else {
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
    }
    
    if (!CMSampleBufferIsValid(sampleBuffer)) {
        return;
    }
    
    // 多个识别，寻找可用识别实体
    if ([self.availableBankCards count] <= 0) {
        return;
    }
    LFBankCard *bankcard = [self.availableBankCards lastObject];
//    TestLinkface *bankcard = [self.availableBankCards lastObject];
    [self.availableBankCards removeObject:bankcard];
    
    CFRetain(sampleBuffer);
    CGRect rectW = self.recWindow;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        _iMoveDeltaCopy = _iMoveDelta ;
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        uint8_t *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        uint8_t *window_buffer = [self transformRGBAtoRGB:baseAddress width:width height:height];
        size_t realWidth  = rectW.size.width;
        size_t realHeight = rectW.size.height;
        
        bankcard.appID = self.appID;
        bankcard.appSecret = self.appSecret;
        bankcard.isVertical = self.isVertical;
        bankcard.isAuto = self.isAuto;
        int iResult;
        @synchronized (self) {
            iResult = [bankcard recognizeCardWithBuffer:window_buffer width:(int)realWidth height:(int)realHeight ] ;
        }
        
        if ( iResult == 2 ) {
            UIImage *image = [self  imageFromCharRef:window_buffer withWidth:realWidth andHeight:realHeight];
//            UIImage *fullImage = [self imageFromSampleBuffer:sampleBuffer];
//            [bankcard setImgOriginCaptured:fullImage];
            [bankcard setImgOriginCroped:image];
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(captureReader:getCardResult:)]) {
                    [self.delegate captureReader:self getCardResult:bankcard];
                }
            });
        }
        free(window_buffer);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CFRelease(sampleBuffer);
        [self saveBankCardInAvailableBankCards:bankcard];
        
    });
    return ;
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

- (uint8_t*)transformRGBAtoRGB:(uint8_t*)baseAddress width:(int)width height:(int)height{
    uint8_t *window_buffer = malloc(buffer_size);
    int dn = 0;
    int on = 0;
    CGRect rectW = self.recWindow;
    for (int y=0; y< height; y++) {
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

- (void)saveBankCardInAvailableBankCards:(id)Object{
    [self.availableBankCards addObject:Object];
    if (self.bNeedChangeFrame == YES && self.availableBankCards.count > 0) {
        [self loopSetBankCardFrame:_tempCardWindowForKVO];
    }
}


#pragma mark - Change Scan View

- (void)moveWindowVerticalFromCenterWithDelta:(int) iDelta   //  iDeltaY == 0 in center , < 0 move up, > 0 move down
{
    if (self.isScanVerticalCard||!(self.orientation == AVCaptureVideoOrientationPortrait)) {
        return;
    }
    
    _iMoveDelta = iDelta;
    
    CGFloat realHeight = SCREEN_HEIGHT;
    BOOL bDeltaNagative = _iMoveDelta < 0;
    BOOL bDeltaPositive = _iMoveDelta > 0 ;
    
    //set scan boundary
    if((self.maskView.windowFrame.origin.y + _iMoveDelta) < SCAN_BOUNDARY && bDeltaNagative){
        _iMoveDelta = -self.maskView.windowFrame.origin.y + SCAN_BOUNDARY;
    }
    
    if((self.maskView.windowFrame.origin.y + self.maskView.windowFrame.size.height + _iMoveDelta + SCAN_BOUNDARY > realHeight) && bDeltaPositive){
        _iMoveDelta = realHeight - self.maskView.windowFrame.origin.y - self.maskView.windowFrame.size.height - SCAN_BOUNDARY;
    }

    if ((self.recWindow.origin.y + (CGFloat)_iMoveDelta / realHeight * (CGFloat)self.iVideoHeight) <0) {
        _iMoveDelta = -1 * self.recWindow.origin.y / (CGFloat)self.iVideoHeight * realHeight;
    }
    if ((self.recWindow.origin.y + (CGFloat)_iMoveDelta / realHeight * (CGFloat)self.iVideoHeight + self.recWindow.size.height > (CGFloat)self.iVideoHeight)) {
        _iMoveDelta = realHeight - self.recWindow.origin.y / (CGFloat)self.iVideoHeight * realHeight;
    }
    CGRect tmpRect = self.recWindow;
    if (self.iVideoHeight > self.iVideoWidth) {
        NSInteger iFitIPhone4Size = 0;
        if (realHeight == 480) {
            iFitIPhone4Size = 200;//For fit ip4 ratio
        }
        tmpRect.origin.y += (CGFloat)_iMoveDelta / realHeight * ((CGFloat)self.iVideoHeight - iFitIPhone4Size);
    }
    self.recWindow = tmpRect;

    [self.maskView moveWindowDeltaY:_iMoveDelta] ;
    
}

- (void)changeScanWindowToVertical:(BOOL)isVertical{
    self.isScanVerticalCard = isVertical;
    [self setVideoOrientation:self.captureVideoOrientation];
}

- (void)setVideoOrientation:(AVCaptureVideoOrientation)orientation {
    [super setVideoOrientation:orientation];
    buffer_size = sizeof(unsigned char) * self.recWindow.size.width * self.recWindow.size.height * PIXEL_COMPONENT_NUM;
    [self loopSetBankCardFrame:CGRectMake(0, 0, self.recWindow.size.width, self.recWindow.size.height)];
}

- (void)loopSetBankCardFrame:(CGRect)cardWindow{
    self.bNeedChangeFrame = YES;
    if ([self.availableBankCards count] > 0) {
        for (LFBankCard *b in self.availableBankCards) {
            b.isScanVerticalCard = self.isScanVerticalCard;
        }
        self.bNeedChangeFrame = NO;
    }else{
//                NSLog(@"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^LOOPING^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
        _tempCardWindowForKVO = cardWindow;
    }
    
}

- (CGRect)getMaskFrame {
    if (self.captureVideoOrientation == AVCaptureVideoOrientationPortrait) {
        return self.isScanVerticalCard?  MASK_WINDOW_V:MASK_WINDOW_H;
    } else {
        return self.isScanVerticalCard? MASK_BANKCARD_WINDOW_H:MASK_BANKCARD_WINDOW_V;
    }
}

@end
