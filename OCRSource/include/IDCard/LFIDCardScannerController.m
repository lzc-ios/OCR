//
//  FaceCaptureController.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "LFIDCardScannerController.h"
#import "LFIDCardReader.h"

//#define LIB_STAPI

#ifdef LIB_STAPI
#import "STAPI.h"
#endif

@interface LFIDCardScannerController () < LFIDCardScannerControllerDelegate,LFCaptureReaderDelegate >

@property (nonatomic , strong) UILabel *labelLiveness;
@property (nonatomic) LFIDCardItemOption tempOption;
@property (nonatomic, assign) int iMoveDelte;
@property (nonatomic, readonly) LFIDCardReader *IDCardReader;
@property (nonatomic, assign) BOOL findCard;

@end

@implementation LFIDCardScannerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self uniqueInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self uniqueInit];
    }
    return self;
}

- (void)uniqueInit {
    _cardMode = kIDCardSmart;
    _findCard = NO;
}

- (void)viewDidLoad {
    self.iMode = kCaptureCard;
    [super viewDidLoad];
    [self.IDCardReader setRecognizeRect:self.maskWindowRect inFullRect:self.view.frame];
    [self.IDCardReader setVideoOrientation:self.captureOrientation];
    self.IDCardReader.snapshotSeconds = self.snapshotSeconds;
    [self.IDCardReader setMode:self.cardMode];
    [self.IDCardReader moveWindowVerticalFromCenterWithDelta:self.iMoveDelte];
    [self setRecognizeItemOption:_tempOption];
    [self.capture.captureSession startRunning];
}

- (LFIDCardReader*)IDCardReader{
    if ([self.captureReader isKindOfClass:[LFIDCardReader class]]) {
        return (LFIDCardReader *)self.captureReader;
    }
    return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)captureReader:(LFCaptureReader *)reader getCardResult:(LFIDCard *)cardResult {
    [self callDelegate_getCard:cardResult.imgOriginCaptured withInformation:cardResult];
}

- (void) callDelegate_getCard:(UIImage *) image withInformation:(LFIDCard *)LFIDCard
{
    [self doRecognitionProcess:NO];
    [self getResult:LFIDCard image:image];
}

- (void)getResult:(LFIDCard *)idcard image:(UIImage *)image{
    _findCard = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(getCardResult:)]) {
        [self doRecognitionProcess:NO];
        [self.delegate getCardResult:idcard];
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(getCard:withInformation:)]) {
        [self doRecognitionProcess:NO] ;  // 关闭识别
        [self.delegate getCard:image withInformation:idcard];
    }
}

- (void)scannerException:(NSException*)e   // catch the exception
{
    if ( [self.delegate respondsToSelector:@selector(scannerException:)] ) {
        [self.delegate scannerException:e] ;
    }
}

- (void)receivedError:(NSInteger)errorCode {
    if ([self.delegate respondsToSelector:@selector(getError:)]) {
        [self.delegate getError:errorCode];
    }
}

- (void)changeCaptureMode:(NSInteger)iMode{
    [super changeCaptureMode:iMode];
    if (iMode == kCaptureCard || iMode == kCaptureCardBack) {
        if (CAPTURE_SESSION_QUALITY > 1) {
            if ([self.capture.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
                [self.capture.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
            }
        }
        LFIDCardReader *reader  = [[LFIDCardReader alloc] initWithLicensePath:nil shouldFullCard:self.shouldFullCard];
        [reader setVideoOrientation:self.captureOrientation];
        CGRect realWindow;
        UIInterfaceOrientation orientation;
        CGRect videoWindow = [reader getMaskFrame];
        realWindow = CGRectMake(videoWindow.origin.x / reader.iVideoWidth * SCREEN_WIDTH, videoWindow.origin.y / reader.iVideoHeight * SCREEN_HEIGHT, videoWindow.size.width / reader.iVideoWidth * SCREEN_WIDTH, videoWindow.size.height / reader.iVideoHeight * SCREEN_HEIGHT);
        
        switch (self.captureOrientation) {
            case AVCaptureVideoOrientationPortrait:
            {
                orientation = UIInterfaceOrientationPortrait;
            }
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
            {
                orientation = UIInterfaceOrientationLandscapeLeft;
            }
                break;
            case AVCaptureVideoOrientationLandscapeRight:
            {
                orientation = UIInterfaceOrientationLandscapeRight;
            }
                break;
            default:
            {
                orientation = UIInterfaceOrientationPortrait;
            }
                break;
        }
        LFIDCardMaskView *cardMaskView = [[LFIDCardMaskView alloc] initWithFrame:self.view.bounds andWindowFrame:realWindow Orientation:orientation];
        reader.maskView = cardMaskView;
        self.readerView = cardMaskView;
        reader.appID = self.appID;
        reader.appSecret = self.appSecret;
        reader.isVertical = self.isVertical;
        reader.isAuto = self.isAuto;
        reader.bDebug = self.bDebug;
        reader.returnType= self.returnType;
        self.captureReader = reader;
        [self.captureReader setDelegate:self];
        [self.captureReader setOrientation:orientation];
        [self.capture addCaptureOutput:self.captureReader.captureOutput];
        
        [self.view addSubview:self.readerView];
        
        [self.view addSubview:self.btnCancel] ;
    }
}

- (void)setRecognizeItemOption:(LFIDCardItemOption)option {
    if(self.captureReader){
        [self.IDCardReader setRecognizeItemOption:option];
        _tempOption = option;
    }else{
        _tempOption = option;
    }
}

//  fDeltaY == 0 in center , < 0 move up, > 0 move down
- (void)moveWindowVerticalFromCenterWithDelta:(int) iDeltaY
{
    self.iMoveDelte = iDeltaY;
    [self.IDCardReader moveWindowVerticalFromCenterWithDelta:iDeltaY] ;
}

-(void)resetAutoCancelTimer{
    [super resetAutoCancelTimer];
    _findCard = NO;
}

-(BOOL)hasFindCard{
    return _findCard;
}

#pragma mark - getters & setters

- (void)setCardMode:(LFIDCardMode)cardMode
{
    if (_cardMode != cardMode) {
        _cardMode = cardMode;
        [self.IDCardReader setMode:self.cardMode];
    }
}

- (CGRect)maskWindowRect {
    return self.readerView.windowFrame;
}

- (void)setHintLabel:(UILabel *)label{
    [self.IDCardReader setHintLabel:label];
}

-(void)setDelegate:(id<LFIDCardScannerControllerDelegate>)delegate{
    _delegate = delegate;
    self.captureDelegate = delegate;
}

- (void) doRecognitionProcess:(BOOL) bProcessEnabled
{
    [super doRecognitionProcess:bProcessEnabled];
}

-(void)hideMaskView:(BOOL)bHide{
    [super hideMaskView:bHide];
}

-(void)didCancel{
    [super didCancel];
}
@end
