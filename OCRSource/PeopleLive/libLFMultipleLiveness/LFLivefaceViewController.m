
//  LFLivefaceViewController.m
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFLivefaceViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreImage/CoreImage.h>
#import "LFLivenessDetector.h"
#import "LFLivenessCommon.h"
#import "LFCircleView.h"
#import "YFGIFImageView.h"
#import "UIDevice+MDFHardware.h"

@interface LFLivefaceViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, LFLivenessDetectorDelegate>

{
    int _indexOfCase;
    
    float _fScale; // Scale factor between video frame & display preview
    
    float _fImageWidth;
    float _fImageHeight;
    
    BOOL _bSingleCore;
    BOOL _b3_5InchScreen;
    
    int _iFramesCount;
    NSArray *_arrDetection;
}


@property (nonatomic , strong) UIView *preview;

@property (nonatomic , strong) YFGIFImageView *imageAnimationView;

@property (nonatomic , strong) UILabel *lblPrompt;
@property (nonatomic , strong) UIImageView *imageMaskView;
@property (nonatomic , strong) UIButton *btnSound;
@property (nonatomic, strong) UIButton *btnBack;

@property (nonatomic , assign) float fCurrentPlayerVolume;

@property (nonatomic , strong) AVCaptureSession *session;

@property (nonatomic) dispatch_queue_t queueBuffer;
@property (nonatomic , strong) AVCaptureDevice *deviceFront;

@property (nonatomic , strong) UIView *stepBackGroundView;
@property (nonatomic , strong) UILabel *lblProcessing;

@property (nonatomic , strong) AVCaptureDeviceInput * deviceInput;
@property (nonatomic , strong) AVCaptureVideoDataOutput * dataOutput;

@property (nonatomic , weak) id <LFLivenessDetectorDelegate>delegate;

@property (nonatomic , strong) LFLivenessDetector *detector;

@property (nonatomic) dispatch_queue_t callBackQueue;


@property (nonatomic , strong) AVAudioPlayer *blinkAudioPlayer;
@property (nonatomic , strong) AVAudioPlayer *mouthAudioPlayer;
@property (nonatomic , strong) AVAudioPlayer *nodAudioPlayer;
@property (nonatomic , strong) AVAudioPlayer *yawAudioPlayer;
@property (nonatomic , strong) AVAudioPlayer *currentAudioPlayer;

@property (nonatomic , copy) NSString *strBundlePath;

@property (nonatomic , assign) BOOL bShowCountDownView;

@property (nonatomic , strong) LFCircleView *circleView;

@property (nonatomic , assign) float fMaxDuration;

@end

@implementation LFLivefaceViewController

- (void)dealloc
{
    if (self.session) {
        [self.session beginConfiguration];
        [self.session removeOutput:self.dataOutput];
        [self.session removeInput:self.deviceInput];
        [self.session commitConfiguration];
        
        if ([self.session isRunning]) {
            [self.session stopRunning];
        }
        self.session = nil;
    }
    
    if ([self.currentAudioPlayer isPlaying]) {
        [self.currentAudioPlayer stop];
    }
    
    if ([self.imageAnimationView isGIFPlaying]) {
        [self.imageAnimationView stopGIF];
    }
}

#pragma - mark Life Cycle

- (instancetype)initWithDuration:(double)fDuration
             resourcesBundlePath:(NSString *)strBundlePath
{
    if (self = [super init]) {
        if (!strBundlePath || [strBundlePath isEqualToString:@""] || ![[NSFileManager defaultManager] fileExistsAtPath:strBundlePath]) {
            NSLog(@" ╔————————————————————————— WARNING ————————————————————————╗");
            NSLog(@" |                                                          |");
            NSLog(@" |  Please add lf_liveness_resource.bundle to your project !|");
            NSLog(@" |                                                          |");
            NSLog(@" ╚——————————————————————————————————————————————————————————╝");
            return nil;
        }
        self.detector = [[LFLivenessDetector alloc] initWithDuration:fDuration
                                                 resourcesBundlePath:strBundlePath];
        
        self.bShowCountDownView = fDuration > 0;
        self.fMaxDuration = fDuration;
        self.strBundlePath = strBundlePath;
        self.bVoicePrompt = YES;
        self.fCurrentPlayerVolume = 0.8;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    _bSingleCore = ([NSProcessInfo processInfo].processorCount == 1);
    _b3_5InchScreen = (kLFScreenHeight == 480);
    self.callBackQueue = dispatch_queue_create("UNIVERSAL_CALL_BACK_QUEUE", NULL);
    
    [self setupUI];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    BOOL bSetupCaptureSession = [self setupCaptureSession];
    if (!bSetupCaptureSession) {
        return;
    }
    [self setupAudio];
    if (self.session && ![self.session isRunning]) {
        [self.session startRunning];
    }
}

#pragma mark - Common set

- (void)setupUI
{
    UIImage *imageMask = nil;
    
    if (isFullScreen) {
        if (LFiPhoneX){
            imageMask = [self imageWithFullFileName:@"pic_blackbackground_iphonex.png"];
        }else if (LFIPHONE_Xr){
           imageMask = [self imageWithFullFileName:@"huoti@2x.png"];
        }else if (LFIPHONE_Xs_Max){
           imageMask = [self imageWithFullFileName:@"huoti@3x.png"];
        }
    } else if (KIsIpad) {
        imageMask = [self imageWithFullFileName:@"pic_blackbackground_ipad.png"];
    } else {
        imageMask = [self imageWithFullFileName:@"pic_blackbackground.png"];
    }
    
    self.preview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kLFScreenWidth, kLFScreenHeight)];
    self.preview.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.preview];
    
    self.imageMaskView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kLFScreenWidth, kLFScreenHeight)];
    self.imageMaskView.image = imageMask;
    self.imageMaskView.userInteractionEnabled = YES;
    [self.preview addSubview:self.imageMaskView];
    
    self.stepBackGroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _arrDetection.count * 20.0 + (_arrDetection.count - 1) * 5.0, 20.0)];
    self.stepBackGroundView.center = CGPointMake(kLFScreenWidth / 2.0, kLFScreenHeight - 26.0);
    self.stepBackGroundView.userInteractionEnabled = NO;
    [self.imageMaskView addSubview:self.stepBackGroundView];
    
    for (int i = 0; i < _arrDetection.count;  i ++) {
        UIButton *btnNumber = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnNumber setFrame:CGRectMake(i * 25.0, 0, 20.0, 20.0)];
        
        // 现在有 5 张图 , 做保护
        int j = i < 5 ? i + 1 : 5;
        [btnNumber setImage:[self imageWithFullFileName:[NSString stringWithFormat:@"pic_%d.png" , j]] forState:UIControlStateNormal];
        [btnNumber setImage:[self imageWithFullFileName:[NSString stringWithFormat:@"pic_%dsolid.png" , j]] forState:UIControlStateHighlighted];
        [self.stepBackGroundView addSubview:btnNumber];
    }
    
    CGFloat fAnimationViewWidth = 100.0;
    CGFloat fAnimationViewY = kLFScreenHeight - 21.0 - 10.0 - 18.0 - 100.0;
    fAnimationViewY = _b3_5InchScreen ? fAnimationViewY : kLFScreenHeight - 21.0 - 10.0 - 36.0 - 100.0;
    
    self.imageAnimationView = [[YFGIFImageView alloc] initWithFrame:CGRectMake((kLFScreenWidth - fAnimationViewWidth) / 2, fAnimationViewY, fAnimationViewWidth, fAnimationViewWidth)];
    self.imageAnimationView.layer.masksToBounds = YES;
    self.imageAnimationView.layer.cornerRadius = self.imageAnimationView.frame.size.width / 2;
    self.imageAnimationView.repeatMaxCount = 999;
    [self.imageMaskView addSubview:self.imageAnimationView];
    
    float fWidth = self.imageAnimationView.frame.size.width / 2;
    self.circleView = [[LFCircleView alloc] initWithFrame:CGRectMake(0, 0, fWidth, fWidth)
                                                bodyWidth:2
                                                bodyColor:[UIColor greenColor]
                                                     font:[UIFont boldSystemFontOfSize:28]
                                                textColor:[UIColor whiteColor]
                                                MaxNumber:self.fMaxDuration];
    self.circleView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    self.circleView.center = CGPointMake(self.imageMaskView.frame.size.width - fWidth / 2 - 20, kLFScreenHeight - 50);
    [self.imageMaskView addSubview:self.circleView];
    
    self.lblPrompt = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0, 38.0)];
    self.lblPrompt.center = CGPointMake(self.imageAnimationView.center.x, self.imageAnimationView.frame.origin.y - 14.0 - 19.0);
    self.lblPrompt.font = [UIFont systemFontOfSize:20];
    self.lblPrompt.textAlignment = NSTextAlignmentCenter;
    self.lblPrompt.textColor = [UIColor whiteColor];
    self.lblPrompt.layer.cornerRadius = self.lblPrompt.frame.size.height / 2.0;
    self.lblPrompt.layer.masksToBounds = YES;
    self.lblPrompt.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    [self.imageMaskView addSubview:self.lblPrompt];
    
    self.lblProcessing = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kLFScreenWidth, kLFScreenHeight)];
    self.lblProcessing.text = @"处理中，请稍后";
    self.lblProcessing.textColor = [UIColor whiteColor];
    self.lblProcessing.textAlignment = NSTextAlignmentCenter;
    self.lblProcessing.backgroundColor = [UIColor blackColor];
    self.lblProcessing.alpha = 0.5;
    self.lblProcessing.hidden = YES;
    self.lblProcessing.font = [UIFont systemFontOfSize:18.0];
    [self.imageMaskView addSubview:self.lblProcessing];

    UIButton *btnSound = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSound setFrame:CGRectMake(kLFScreenWidth - 40.0, 32 + LFNavigationBarHeightMargin, 40.0, 40.0)];
    [btnSound setImage:[self imageWithFullFileName:[NSString stringWithFormat:@"%@", self.bVoicePrompt ? @"icon_voice.png" : @"icon_novoice.png"]] forState:UIControlStateNormal];
    [btnSound addTarget:self action:@selector(onBtnSound) forControlEvents:UIControlEventTouchUpInside];
    [self.imageMaskView addSubview:btnSound];
    self.btnSound = btnSound;
    
    UIButton *btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnBack setFrame:CGRectMake(20, 32 + LFNavigationBarHeightMargin, 40, 40)];
    [btnBack setImage:[UIImage imageNamed:@"btn_back"] forState:UIControlStateNormal];
    [btnBack addTarget:self action:@selector(btnBackTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageMaskView addSubview:btnBack];
    self.btnBack = btnBack;
}

- (void)setupAudio
{
    NSString *strAppBunldePath = [[NSBundle mainBundle] pathForResource:@"lf_liveness_resource" ofType:@"bundle"];
    NSString *strBlinkPath = [NSString pathWithComponents:@[strAppBunldePath , @"sounds" , @"linkface_notice_blink.mp3"]];
    self.blinkAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:strBlinkPath] error:nil];
    self.blinkAudioPlayer.volume = self.fCurrentPlayerVolume;
    self.blinkAudioPlayer.numberOfLoops = -1;
    [self.blinkAudioPlayer prepareToPlay];
    
    NSString *strMouthPath = [NSString pathWithComponents:@[strAppBunldePath , @"sounds" , @"linkface_notice_mouth.mp3"]];
    self.mouthAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:strMouthPath] error:nil];
    self.mouthAudioPlayer.volume = _fCurrentPlayerVolume;
    self.mouthAudioPlayer.numberOfLoops = -1;
    [self.mouthAudioPlayer prepareToPlay];
    
    NSString *strNodPath = [NSString pathWithComponents:@[strAppBunldePath , @"sounds" , @"linkface_notice_nod.mp3"]];
    self.nodAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:strNodPath] error:nil];
    self.nodAudioPlayer.volume = _fCurrentPlayerVolume;
    self.nodAudioPlayer.numberOfLoops = -1;
    [self.nodAudioPlayer prepareToPlay];
    
    NSString *strYawPath = [NSString pathWithComponents:@[strAppBunldePath , @"sounds" , @"linkface_notice_yaw.mp3"]];
    self.yawAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:strYawPath] error:nil];
    self.yawAudioPlayer.volume = _fCurrentPlayerVolume;
    self.yawAudioPlayer.numberOfLoops = -1;
    [self.yawAudioPlayer prepareToPlay];
}

- (BOOL)setupCaptureSession
{
    self.session = [[AVCaptureSession alloc] init];
    if (_bSingleCore) {
        // iPhone 4
        self.session.sessionPreset = AVCaptureSessionPresetLow;
        _fImageWidth = 192.0;
        _fImageHeight = 144.0;
        
    } else {
        // iPhone 4S, +
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
        _fImageWidth = 640.0;
        _fImageHeight = 480.0;
    }
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    _fScale = _fImageHeight / self.preview.frame.size.width;
    
    captureVideoPreviewLayer.frame = self.preview.frame;
    captureVideoPreviewLayer.position = self.preview.center;
    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.preview.layer insertSublayer:captureVideoPreviewLayer below:self.imageMaskView.layer];
    
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionFront) {
                self.deviceFront = device;
            }
        }
    }
    
    int frameRate;
    CMTime frameDuration = kCMTimeInvalid;
    
    // For single core systems like iPhone 4 and iPod Touch 4th Generation we use a lower resolution and framerate to maintain real-time performance.
    frameRate = _bSingleCore ? 15 : 30;
    frameDuration = CMTimeMake( 1, frameRate );
    
    NSError *error = nil;
    if ( [self.deviceFront lockForConfiguration:&error] ) {
        self.deviceFront.activeVideoMaxFrameDuration = frameDuration;
        self.deviceFront.activeVideoMinFrameDuration = frameDuration;
        [self.deviceFront unlockForConfiguration];
    }
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.deviceFront error:&error];
    self.deviceInput = input;
    if (!input) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(livenessDidFailWithErrorType:detectionType:detectionIndex:data:lfImages:lfVideoData:)]) {
            dispatch_async(_callBackQueue, ^{
                [self.delegate livenessDidFailWithErrorType:LIVENESS_CAMERA_ERROR detectionType:[[_arrDetection firstObject] integerValue] detectionIndex:0 data:nil lfImages:nil lfVideoData:nil];
            });
        }
        return NO;
    }
    self.dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    self.queueBuffer = dispatch_queue_create("LIVENESS_BUFFER_QUEUE", NULL);
    
    [self.dataOutput setSampleBufferDelegate:self queue:self.queueBuffer];
    
    [self.session beginConfiguration];
    
    if ([self.session canAddOutput:self.dataOutput]) {
        [self.session addOutput:self.dataOutput];
    }
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    [self.session commitConfiguration];
    
    return YES;
}

- (UIImage *)imageWithFullFileName:(NSString *)strFileName{
    NSString *strAppBunldePath = [[NSBundle mainBundle] pathForResource:@"lf_liveness_resource" ofType:@"bundle"];
    NSString *strFilePath = [NSString pathWithComponents:@[strAppBunldePath , @"images" , strFileName]];
    return [UIImage imageWithContentsOfFile:strFilePath];
}

#pragma - mark Actions

- (void)onBtnStartDetect
{
    [self startDetection];
}

- (void)startDetection
{
    if (self.session && [self.session isRunning] && self.detector) {
        [self.detector startDetection];
    }
}

- (void)cancelDetection
{
    if (self.detector) {
        [self.detector cancelDetection];
    }
}

- (void)setBVoicePrompt:(BOOL)bVoicePrompt
{
    _bVoicePrompt = bVoicePrompt;
    
    [self setPlayerVolume];
}

- (void)onBtnSound
{
    self.bVoicePrompt = !self.bVoicePrompt;
    
    [self setPlayerVolume];
}

- (void)btnBackTapped:(id)sender
{
    [self cancelDetection];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setPlayerVolume
{
    [self.btnSound setImage:[self imageWithFullFileName:[NSString stringWithFormat:@"%@", self.bVoicePrompt ? @"icon_voice.png" : @"icon_novoice.png"]] forState:UIControlStateNormal];
    self.fCurrentPlayerVolume = self.bVoicePrompt ? 0.8 : 0;
    
    if (self.currentAudioPlayer) {
        self.blinkAudioPlayer.volume = self.fCurrentPlayerVolume;
        self.mouthAudioPlayer.volume = self.fCurrentPlayerVolume;
        self.nodAudioPlayer.volume = self.fCurrentPlayerVolume;
        self.yawAudioPlayer.volume = self.fCurrentPlayerVolume;
    }
}

- (void)displayViewsIfRunning:(BOOL)bRunning
{
    self.imageAnimationView.hidden = !bRunning;
    self.lblPrompt.hidden = !bRunning;
    self.stepBackGroundView.hidden = !bRunning;
    self.circleView.hidden = self.bShowCountDownView ? !bRunning : YES;
}

- (void)clearStepViewAndStopSound
{
    if (self.currentAudioPlayer) {
        
        [self stopAudioPlayer];
    }
    
    for (UIButton *btnNumber in self.stepBackGroundView.subviews) {
        [btnNumber setHighlighted:NO];
    }
}

#pragma - mark AVCaptureVideoDataOutputSampleBufferDelegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (self.detector) {
        [self.detector trackAndDetectWithCMSampleBuffer:sampleBuffer faceOrientation:LIVE_FACE_LEFT];
    }
}

#pragma - mark Public Methods

- (void)setDelegate:(id<LFLivenessDetectorDelegate>)delegate callBackQueue:(dispatch_queue_t)queue detectionSequence:(NSArray *)arrDetection
{
    if (!arrDetection.count) {
        NSLog(@" ╔———————————— WARNING ————————————╗");
        NSLog(@" |                                 |");
        NSLog(@" |  Please set detection sequence !|");
        NSLog(@" |                                 |");
        NSLog(@" ╚—————————————————————————————————╝");
    } else {
        [self.detector setDelegate:self
                     callBackQueue:queue
                 detectionSequence:arrDetection];
        
        _arrDetection = [arrDetection mutableCopy];
    }
    
    if (self.delegate != delegate) {
        self.delegate = delegate;
    }
    
    if (_callBackQueue != queue) {
        _callBackQueue = queue;
    }
}

+ (NSString *)getSDKVersion
{
    return [LFLivenessDetector getSDKVersion];
}

#pragma - mark Private Methods

- (void)setOutputType:(LivefaceOutputType)iOutputType complexity:(LivefaceComplexity)iComplexity
{
    if (self.detector) {
        [self.detector setOutputType:iOutputType complexity:iComplexity];
    }
}

- (void)showPromptTextWithType:(LivefaceDetectionType)type detectionIndex:(int)iIndex
{
    UIButton *btnNumber = [self.stepBackGroundView.subviews objectAtIndex:iIndex];
    [btnNumber setHighlighted:YES];
    
    if ([self.imageAnimationView isGIFPlaying]) {
        [self.imageAnimationView stopGIF];
    }
    
    if (self.currentAudioPlayer) {
        if ([self.currentAudioPlayer isPlaying]) {
            [self.currentAudioPlayer stop];
        }
        self.currentAudioPlayer.currentTime = 0;
    }

    switch ((NSInteger)type) {
        case LIVE_YAW:
        {
            self.lblPrompt.text = @"请摇摇头";
            self.currentAudioPlayer = self.yawAudioPlayer;
            break;
        }
            
        case LIVE_BLINK:
        {
            self.lblPrompt.text = @"请眨眨眼";
            self.currentAudioPlayer = self.blinkAudioPlayer;
            break;
        }
            
        case LIVE_MOUTH:
        {
            self.lblPrompt.text = @"请张张嘴";
            self.currentAudioPlayer = self.mouthAudioPlayer;
            break;
        }
        case LIVE_NOD:
        {
            self.lblPrompt.text = @"请点点头";
            self.currentAudioPlayer = self.nodAudioPlayer;
            break;
        }
    }
    
    if (self.currentAudioPlayer) {
        [self stopAudioPlayer];
        [self.currentAudioPlayer play];
    }
    self.imageAnimationView.gifData = [self gifDataWithDetectionType:type];
    if (![self.imageAnimationView isGIFPlaying]) {
        [self.imageAnimationView startGIF];
    }
}

- (void)stopAudioPlayer
{
    if ([self.currentAudioPlayer isPlaying]) {
        [self.currentAudioPlayer stop];
    }
    self.currentAudioPlayer.currentTime = 0;
}

- (NSData *)gifDataWithDetectionType:(NSInteger)type
{
    NSString *gifImageName = @"";
    switch (type) {
        case LIVE_YAW:
        {
        gifImageName = @"yaw.gif";
        break;
        }
            
        case LIVE_BLINK:
        {
        gifImageName = @"blink.gif";
        break;
        }
            
        case LIVE_MOUTH:
        {
        gifImageName = @"mouth.gif";
        break;
        }
        case LIVE_NOD:
        {
        gifImageName = @"pitch.gif";
        break;
        }
    }
    
    NSString *strBundlePath = [[NSBundle mainBundle] pathForResource:@"lf_liveness_resource" ofType:@"bundle"];
    NSData *gifData = [NSData dataWithContentsOfFile:[NSString pathWithComponents:@[strBundlePath , @"images" , gifImageName]]];
    return gifData;
}

#pragma - mark LFLivenessDetectorDelegate

- (void)livenessDidStartDetectionWithDetectionType:(LivefaceDetectionType)iDetectionType detectionIndex:(int)iDetectionIndex
{
    [self showPromptTextWithType:iDetectionType detectionIndex:iDetectionIndex];
    [self displayViewsIfRunning:YES];

    if (self.delegate && [self.delegate respondsToSelector:@selector(livenessDidStartDetectionWithDetectionType:detectionIndex:)]) {
        dispatch_async(_callBackQueue, ^{
            [self.delegate livenessDidStartDetectionWithDetectionType:iDetectionType detectionIndex:iDetectionType];
        });
    }
}

- (void)videoFrameRate:(int)rate{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoFrameRate:)]) {
        dispatch_async(_callBackQueue, ^{
            [self.delegate videoFrameRate:rate];
        });
    }
}

- (void)livenessTimeDidPast:(double)dPast durationPerModel:(double)dDurationPerModel
{
    if (dDurationPerModel != 0) {
        self.circleView.fAnglePercent = (dPast / dDurationPerModel);
        if (self.delegate && [self.delegate respondsToSelector:@selector(livenessTimeDidPast:durationPerModel:)]) {
            dispatch_async(_callBackQueue, ^{
                [self.delegate livenessTimeDidPast:dPast durationPerModel:dDurationPerModel];
            });
        }
    }
}

- (void)livenessDidSuccessfulGetData:(NSData *)data lfImages:(NSArray *)arrLFImage lfVideoData:(NSData *)lfVideoData
{
    [self clearStepViewAndStopSound];
    [self displayViewsIfRunning:NO];
    if (self.delegate && [self.delegate respondsToSelector:@selector(livenessDidSuccessfulGetData:lfImages:lfVideoData:)]) {
        dispatch_async(_callBackQueue, ^{
            [self.delegate livenessDidSuccessfulGetData:data lfImages:arrLFImage lfVideoData:lfVideoData];
        });
    }
}

- (void)livenessDidFailWithErrorType:(LivefaceErrorType)iErrorType detectionType:(LivefaceDetectionType)iDetectionType detectionIndex:(int)iDetectionIndex data:(NSData *)data lfImages:(NSArray *)arrLFImage lfVideoData:(NSData *)lfVideoData
{
    
    [self clearStepViewAndStopSound];
    [self displayViewsIfRunning:NO];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(livenessDidFailWithErrorType:detectionType:detectionIndex:data:lfImages:lfVideoData:)]) {
        dispatch_async(_callBackQueue, ^{
            [self.delegate livenessDidFailWithErrorType:iErrorType detectionType:iDetectionType detectionIndex:iDetectionIndex data:data lfImages:arrLFImage lfVideoData:lfVideoData];
        });
    }
}

- (void)livenessDidCancelWithDetectionType:(LivefaceDetectionType)iDetectionType detectionIndex:(int)iDetectionIndex
{
    [self clearStepViewAndStopSound];
    [self displayViewsIfRunning:NO];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(livenessDidCancelWithDetectionType:detectionIndex:)]) {
        dispatch_async(_callBackQueue, ^{
            [self.delegate livenessDidCancelWithDetectionType:iDetectionType detectionIndex:iDetectionIndex];
        });
    }
}

@end
