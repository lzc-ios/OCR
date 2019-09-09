//
//  LFBankCardScannerController.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFBankCardScannerController.h"
#import "LFBankCardReader.h"

@interface LFBankCardScannerController () <LFBankCardScannerControllerDelegate, LFCaptureReaderDelegate>
@property (nonatomic, assign) int iMoveDelte;
@property (nonatomic, assign) BOOL bScanVerticalCard;
@property (nonatomic, readonly) LFBankCardReader* bankCardReader;
@property (nonatomic, assign) BOOL findCard;
@end

@implementation LFBankCardScannerController

- (instancetype)initWithOrientation:(AVCaptureVideoOrientation)orientation licenseName:(NSString *)licenseName isVertical:(BOOL)isVertical shouldFullCard:(BOOL)shouldFullCard
{
    self = [self initWithOrientation:orientation licensePath:[[NSBundle mainBundle] pathForResource:licenseName ofType:@"lic"] isVertical:isVertical shouldFullCard:shouldFullCard];
    return self;
}

- (instancetype)initWithOrientation:(AVCaptureVideoOrientation)orientation
                        licensePath:(nullable NSString *)licensePath
                         isVertical:(BOOL)isVertical
                     shouldFullCard:(BOOL)shouldFullCard
{
    self = [super initWithOrientation:orientation licensePath:licensePath shouldFullCard:shouldFullCard];
    if (self) {
        self.bScanVerticalCard = isVertical;
        self.findCard = NO;
    }
    return self;
}

- (void)viewDidLoad {
    self.iMode = kCaptureBankCard;
    [super viewDidLoad];
    
    // 显示界面
    [self.captureReader setVideoOrientation:self.captureOrientation];
    self.bankCardReader.snapshotSeconds = self.snapshotSeconds;
    [self.bankCardReader changeScanWindowToVertical:self.bScanVerticalCard];
    [self setIsScanVerticalCard:self.bScanVerticalCard];
    [self.bankCardReader setIsScanVerticalCard:self.bScanVerticalCard];
    [self.bankCardReader moveWindowVerticalFromCenterWithDelta:self.iMoveDelte];
    self.btnChangeScanDirection.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.bDebug) {
        NSLog(@"x:%f, y:%f, w:%f, h:%f",self.readerView.windowFrame.origin.x, self.readerView.windowFrame.origin.y, self.readerView.windowFrame.size.width, self.readerView.windowFrame.size.height);
    }
}

-(BOOL)isVerticalAnimation{
    if (self.captureOrientation == AVCaptureVideoOrientationPortrait) {
        return self.bScanVerticalCard;
    } else {
        return !self.bScanVerticalCard;
    }
}

- (LFBankCardReader*) bankCardReader{
    if([self.captureReader isKindOfClass:[LFBankCardReader class]]) {
        return (LFBankCardReader*)self.captureReader;
    }
    return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//  fDeltaY == 0 in center , < 0 move up, > 0 move down
- (void)moveWindowVerticalFromCenterWithDelta:(int) iDeltaY
{
    self.iMoveDelte = iDeltaY;
    [self.bankCardReader moveWindowVerticalFromCenterWithDelta:iDeltaY] ;
}

- (void)changeScanWindowForVerticalCard:(BOOL)isVertical{
    [self.bankCardReader changeScanWindowToVertical:isVertical];
}

- (void)setIsScanVerticalCard:(BOOL)isScanVerticalCard{
    self.bScanVerticalCard = isScanVerticalCard;
//    self.btnChangeScanDirection.tag = isScanVerticalCard;
    [self.readerView changeScanWindowDirection:isScanVerticalCard];
    [self.bankCardReader setRecognizeRect:self.maskWindowRect inFullRect:self.view.frame];
    [self.bankCardReader changeScanWindowToVertical:isScanVerticalCard];
    [self.bankCardReader setIsScanVerticalCard:isScanVerticalCard];
    
    NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
    if (isScanVerticalCard) {
        self.btnChangeScanDirection.tag = 1;
        [self.btnChangeScanDirection setImage:[UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"scan_vertical" ofType:@"png"]] forState:UIControlStateNormal];
        self.bankCardReader.isVertical = 1;
    }else {
        self.btnChangeScanDirection.tag = 0;
        [self.btnChangeScanDirection setImage:[UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"scan_horizontal" ofType:@"png"]] forState:UIControlStateNormal];
        self.bankCardReader.isVertical = 0;
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)setShowChangeScanModeButton:(BOOL)bShowButton{
    self.btnChangeScanDirection.hidden = !bShowButton;
}

- (void)captureReader:(LFCaptureReader *)reader getCardResult:(LFBankCard *)cardResult {
    [self callDelegate_getCard:cardResult.imgOriginCaptured withInformation:cardResult];
}

- (void) callDelegate_getCard:(UIImage *) image withInformation:(LFBankCard *)bankCard
{
    [self doRecognitionProcess:NO];
    [self getResult:bankCard image:image];
}

// 获取到照片
- (void)getResult:(LFBankCard *)bankCard image:(UIImage *)image{
    if (self.delegate && [self.delegate respondsToSelector:@selector(getCardResult:)]) {
        [self doRecognitionProcess:NO];
        [self.delegate getCardResult:bankCard];
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(getCardImage:withCardInfo:)]) {
        [self doRecognitionProcess:NO] ;  // 关闭识别
        [self.delegate getCardImage:image withCardInfo:bankCard];
    }
    _findCard = YES;
}


-(BOOL)hasFindCard{
    return _findCard;
}

- (void)changeCaptureMode:(NSInteger)iMode
{
    if(iMode == kCaptureBankCard) {
        if (CAPTURE_SESSION_QUALITY > 1) {
            if ([self.capture.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
                [self.capture.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
            }
            
        }
        LFBankCardReader *reader  = [[LFBankCardReader alloc] initWithLicensePath:nil shouldFullCard:self.shouldFullCard]  ;
        [reader setVideoOrientation:self.captureOrientation];
        reader.appID = self.appID;
        reader.appSecret = self.appSecret;
        reader.isVertical = self.isVertical;
        reader.isAuto = self.isAuto;
        CGRect realWindow;
        UIInterfaceOrientation orientation;
        
        self.btnChangeScanDirection.hidden = NO;
        CGRect videoWindow = [reader getMaskFrame];
        
        NSLog(@" reader.iVideoWidth * SCREEN_WIDTH  == %f",reader.iVideoWidth * SCREEN_WIDTH);
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
        LFBankCardMaskView *cardMaskView = [[LFBankCardMaskView alloc] initWithFrame:self.view.bounds andWindowFrame:realWindow Orientation:orientation];
        reader.maskView = cardMaskView ;
        self.readerView = cardMaskView;
        reader.bDebug = self.bDebug ;
        self.captureReader = reader ;
        [self.captureReader setDelegate:self];
        [self.captureReader setOrientation:orientation];
        [self.capture addCaptureOutput:self.captureReader.captureOutput];
        
        [self.view addSubview:self.readerView];
        
        [self.view addSubview:self.btnCancel] ;
        [self.view addSubview:self.btnChangeScanDirection];

    }
}

- (CGRect)maskWindowRect {
    return self.readerView.windowFrame;
}

- (void)changeScanDirection:(UIButton *)button{
    button.enabled = NO;
    self.isScanVerticalCard = !button.tag;
    [self moveWindowVerticalFromCenterWithDelta:self.iMoveDelte];
    [self resetAutoCancelTimer];
    button.enabled = YES;
}

#pragma mark - getters & setters
- (void)receivedError:(NSInteger)errorCode {
    if ([self.delegate respondsToSelector:@selector(getError:)]) {
        [self.delegate getError:errorCode];
    }
}
-(void)doRecognitionProcess:(BOOL)bProcessEnabled{
    [super doRecognitionProcess:bProcessEnabled];
}

-(void)didCancel{
    [super didCancel];
}

-(void)setDelegate:(id<LFBankCardScannerControllerDelegate>)delegate{
    _delegate = delegate;
    self.captureDelegate = delegate;
}

-(void)dealloc{
    
}
@end
