//
//  LFMultipleLivenessController.m
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFMultipleLivenessController.h"
#import "LFLivefaceViewController.h"
#import "NSObject+LFAccess.h"


@interface LFMultipleLivenessController () <LFLivenessDetectorDelegate>
{
    NSString *_strJsonCommand;
}

@property (nonatomic , assign) LivefaceOutputType iOutputType;

@property (nonatomic , strong) LFLivefaceViewController *livefaceVC;

@property (nonatomic , assign) BOOL bVoicePromptOn;

@property (nonatomic, copy) NSString *strBundlePath;

@end

@implementation LFMultipleLivenessController

- (void)dealloc
{
    [self.livefaceVC removeFromParentViewController];
    self.livefaceVC = nil;
}

#pragma mark - Init

- (instancetype)init
{
    if (self = [super init]) {
        self.bVoicePromptOn = YES;
    }
    return self;
}

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.livefaceVC || !_strJsonCommand) {
        [self callBackWithBadJsonError];
        return;
    }
    
    [self addChildViewController:self.livefaceVC];
    [self.view addSubview:self.livefaceVC.view];
}

#pragma mark - Public Methods

- (BOOL)setJsonCommand:(NSString *)strJsonCommand
{
    _strJsonCommand = strJsonCommand;
    _strBundlePath = [[NSBundle mainBundle] pathForResource:@"lf_liveness_resource" ofType:@"bundle"];
    
    NSError *error = nil;
    NSDictionary *dicJson = [NSJSONSerialization JSONObjectWithData:[_strJsonCommand dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
    
    if (error) {
        return NO;
    }
    
    LFLivefaceViewController *liveVC = [self createControllerWithJsonDic:dicJson];
    
    if (!liveVC) {
        return NO;
    }
    self.livefaceVC = liveVC;
    return YES;
}

- (void)cancel
{
    if (!self.childViewControllers.firstObject && self.delegate && [self.delegate respondsToSelector:@selector(multiLivenessDidCancel)]) {
        [self.delegate multiLivenessDidCancel];
    }
    [(LFLivefaceViewController *)self.childViewControllers.firstObject cancelDetection];
}

- (void)restart
{
    [(LFLivefaceViewController *)self.childViewControllers.firstObject startDetection];
}

- (NSString *)getLivenessVersion
{
    return [LFLivefaceViewController getSDKVersion];
}

- (void)setVoicePromptOn:(BOOL)bVoicePrompt
{
    self.bVoicePromptOn = bVoicePrompt;
    if (self.livefaceVC) {
        self.livefaceVC.bVoicePrompt = bVoicePrompt;
    }
}

#pragma mark - Private Methods

- (void)selectPlanWithJsonCommand:(NSString *)strJsonCommand
{
    NSError *error = nil;
    NSDictionary *dicJson = [NSJSONSerialization JSONObjectWithData:[strJsonCommand dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
    
    if (error) {
        [self callBackWithBadJsonError];
        return;
    }
    
    UIViewController *targetViewController = [self createControllerWithJsonDic:dicJson];
    
    if (!targetViewController) {
        [self callBackWithBadJsonError];
        return;
    }
    [self.livefaceVC.view removeFromSuperview];
    [self.livefaceVC removeFromParentViewController];
    
    [self addChildViewController:targetViewController];
    UIViewController *currentVC = self.livefaceVC;
    
    [self transitionFromViewController:currentVC toViewController:targetViewController duration:0 options:UIViewAnimationOptionTransitionNone animations:NULL completion:NULL];
    [currentVC removeFromParentViewController];
}

- (void)callBackWithBadJsonError
{
    if (!_strBundlePath || [_strBundlePath isEqualToString:@""] || ![[NSFileManager defaultManager] fileExistsAtPath:_strBundlePath]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(multiLivenessDidFailWithType:DetectionType:DetectionIndex:Data:lfImages:lfVideoData:)]) {
            [self.delegate multiLivenessDidFailWithType:LFMultipleLivenessSourceError DetectionType:LFDETECTION_NONE DetectionIndex:0 Data:nil lfImages:nil lfVideoData:nil];
        }
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(multiLivenessDidFailWithType:DetectionType:DetectionIndex:Data:lfImages:lfVideoData:)]) {
        [self.delegate multiLivenessDidFailWithType:LFMultipleLivenessBadJson
                                        DetectionType:LFDETECTION_NONE
                                       DetectionIndex:0
                                                 Data:nil
                                             lfImages:nil
                                          lfVideoData:nil];
    }
}

- (LivefaceOutputType)getPlanInfoWithJsonDic:(NSDictionary *)dicJson
{
    NSString *strPlan = [dicJson objectNotNullForKey:@"plan"];
    if (!strPlan) {
        return 0;
    }
    LivefaceOutputType iOutput = 0;
    NSString *strOutType = [dicJson objectNotNullForKey:@"outType"];
    
    if (!strOutType) {
        return -1;
    }
    
    if ([strOutType isEqualToString:@"singleImg"]) {
        iOutput = LIVE_OUTPUT_SINGLE_IMAGE;
    } else if ([strOutType isEqualToString:@"multiImg"]) {
        iOutput = LIVE_OUTPUT_MULTI_IMAGE;
    } else if ([strOutType isEqualToString:@"video"]) {
        iOutput = LIVE_OUTPUT_LOW_QUALITY_VIDEO;
    } else if ([strOutType isEqualToString:@"fullVideo"]) {
        iOutput = LIVE_OUTPUT_HIGH_QUALITY_VIDEO;
    } else {
        return -1;
    }
    return iOutput;
}

- (LFLivefaceViewController *)createControllerWithJsonDic:(NSDictionary *)dicJson
{
    NSString *strOutType = [dicJson objectNotNullForKey:@"outType"];
    
    if (!strOutType) {
        return nil;
    }
    
    LFLivefaceViewController *livefaceVC = [[LFLivefaceViewController alloc] initWithDuration:10.0f
                                                                          resourcesBundlePath:_strBundlePath];
    livefaceVC.bVoicePrompt = self.bVoicePromptOn;
    
    LivefaceOutputType iOutputType = 0;
    
    if ([strOutType isEqualToString:@"singleImg"]){
        
        iOutputType = LIVE_OUTPUT_SINGLE_IMAGE;
    }else if ([strOutType isEqualToString:@"multiImg"]){
        
        iOutputType = LIVE_OUTPUT_MULTI_IMAGE;
    }else if ([strOutType isEqualToString:@"video"]){
        
        iOutputType = LIVE_OUTPUT_LOW_QUALITY_VIDEO;
    }else if ([strOutType isEqualToString:@"fullVideo"]){
        
        iOutputType = LIVE_OUTPUT_HIGH_QUALITY_VIDEO;
    }else{
        return nil;
    }
    
    NSArray *arrOptions = [dicJson objectNotNullForKey:@"sequence"];
    
    if (!arrOptions) {
        return nil;
    }
    
    LivefaceComplexity iComplexity = LIVE_COMPLEXITY_NORMAL;
    
    NSMutableArray *arrDetectionType = [NSMutableArray array];
    
    for (NSString *strMotion in arrOptions) {
        LivefaceDetectionType iDetectionType = LIVE_NONE;
        if ([[strMotion uppercaseString] isEqualToString:@"BLINK"]) {
            iDetectionType = LIVE_BLINK;
        } else if ([[strMotion uppercaseString] isEqualToString:@"NOD"]) {
            iDetectionType = LIVE_NOD;
        } else if ([[strMotion uppercaseString] isEqualToString:@"MOUTH"]) {
            iDetectionType = LIVE_MOUTH;
        } else if ([[strMotion uppercaseString] isEqualToString:@"YAW"]) {
            iDetectionType = LIVE_YAW;
        } else {
            return nil;
        }
        [arrDetectionType addObject:@(iDetectionType)];
    }
    
    iComplexity = [[dicJson objectNotNullForKey:@"Complexity"] integerValue];
    [livefaceVC setDelegate:self callBackQueue:dispatch_get_main_queue() detectionSequence:arrDetectionType];
    [livefaceVC setOutputType:iOutputType complexity:iComplexity];
    
    return livefaceVC;
}

#pragma - mark LFLivenessDetectorDelegate

- (void)livenessDidStartDetectionWithDetectionType:(LivefaceDetectionType)iDetectionType detectionIndex:(int)iDetectionIndex
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(multiLivenessDidStart)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate multiLivenessDidStart];
        });
    }
}

- (void)livenessTimeDidPast:(double)dPast durationPerModel:(double)dDurationPerModel
{
    
}

- (void)videoFrameRate:(int)rate
{
    
//    printf("%d FPS\n",rate);
}

- (void)livenessDidSuccessfulGetData:(NSData *)data lfImages:(NSArray *)arrLFImage lfVideoData:(NSData *)lfVideoData
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(multiLivenessDidSuccessfulGetData:lfImages:lfVideoData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate multiLivenessDidSuccessfulGetData:data lfImages:arrLFImage lfVideoData:lfVideoData];
        });
    }
}


- (void)livenessDidFailWithErrorType:(LivefaceErrorType)iErrorType detectionType:(LivefaceDetectionType)iDetectionType detectionIndex:(int)iDetectionIndex data:(NSData *)data lfImages:(NSArray *)arrLFImage lfVideoData:(NSData *)lfVideoData
{
    LFMultipleLivenessError iLFMultipleError = 0;
    switch (iErrorType) {
        case LIVENESS_INIT_FAILD:
        {
            iLFMultipleError = LFMultipleLivenessInitFaild;
        }
            break;
            
        case LIVENESS_CAMERA_ERROR:
        {
            iLFMultipleError = LFMultipleLivenessCameraError;
        }
            break;
            
        case LIVENESS_FACE_CHANGED:
        {
            iLFMultipleError = LFMultipleLivenessFaceChanged;
        }
            break;
            
        case LIVENESS_INTERNAL_ERROR:
        {
            iLFMultipleError = LFMultipleLivenessInternalError;
        }
            break;
            
        case LIVENESS_TIMEOUT:
        {
            iLFMultipleError = LFMultipleLivenessTimeOut;
        }
            break;
            
            
        case LIVENESS_WILL_RESIGN_ACTIVE:
        {
            iLFMultipleError = LFMultipleLivenessWillResignActive;
        }
            break;
        case LIVENESS_BUNDLEID_ERROR:
        {
            iLFMultipleError = LFMultipleLivenessBundleIDError;
        }
            break;
        case LIVENESS_AUTH_EXPIRE:
        {
            iLFMultipleError = LFMultipleLivenessAuthExpire;
        }
            break;
        case LIVENESS_LICENSE_ERROR:
        {
            iLFMultipleError = LFMultipleLivenessLicenseError;
        }
            break;
        case LINENESS_MODEL_EXPIRE:{
            iLFMultipleError = LFMultipleLivenessModelError;
        }
            break;
        case LINENESS_MODEL_SOURCE:{
            iLFMultipleError = LFMultipleLivenessSourceError;
        }
            break;
        case LINENESS_OTHER_ERROR:{
            iLFMultipleError = LFMultipleLivenessOtherError;
        }
            break;
        default:
            break;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(multiLivenessDidFailWithType:DetectionType:DetectionIndex:Data:lfImages:lfVideoData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate multiLivenessDidFailWithType:iLFMultipleError DetectionType:iDetectionIndex DetectionIndex:iDetectionIndex Data:data lfImages:arrLFImage lfVideoData:lfVideoData];
        });
    }
}

- (void)livenessDidCancelWithDetectionType:(LivefaceDetectionType)iDetectionType detectionIndex:(int)iDetectionIndex
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(multiLivenessDidCancel)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate multiLivenessDidCancel];
        });
    }
}

@end
