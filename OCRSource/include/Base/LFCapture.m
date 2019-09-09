//
//  LFCapture.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "LFCapture.h"
#import "LFCommon.h"

@implementation LFCapture
@synthesize
captureSession = _captureSession,
captureDevice = _captureDevice,
captureDeviceInput = _captureDeviceInput,
torchMode = _torchMode;

#pragma mark - getter & setter
- (AVCaptureTorchMode)torchMode
{
    return _torchMode;
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode
{
    [_captureDevice lockForConfiguration:nil];
    if ([_captureDevice  isTorchModeSupported:torchMode]) {
        [_captureDevice setTorchMode:torchMode];
        _torchMode = torchMode;
    }
    [_captureDevice unlockForConfiguration];
}

- (void) setDevicePosition:(AVCaptureDevicePosition) devicePosition
{
    if( _captureDevice.position == devicePosition )
        return ;
    
    [_captureSession beginConfiguration];
    
    [_captureSession removeInput:_captureDeviceInput];
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == devicePosition )
            _captureDevice = device ;
    }
    NSError *error;
    _captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:&error];
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
    }
    
    [_captureSession commitConfiguration];
}

#pragma mark - life cycle
- (id)init
{
    self = [super init];
    if (self) {
        //create capture session
        _captureSession = [AVCaptureSession new];
        //config capture session
        [_captureSession beginConfiguration];
        
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetiFrame1280x720])  {
            [_captureSession setSessionPreset:AVCaptureSessionPresetiFrame1280x720];
        }
        
        //add observer for session
        // add observer for session
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVideoError:) name:AVCaptureSessionRuntimeErrorNotification object:_captureSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVideoStart:) name:AVCaptureSessionDidStartRunningNotification object:_captureSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVideoStop:) name:AVCaptureSessionDidStopRunningNotification object:_captureSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVideoStop:) name:AVCaptureSessionWasInterruptedNotification object:_captureSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVideoStart:) name:AVCaptureSessionInterruptionEndedNotification object:_captureSession];
        //create capture device & capture devie input
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        NSError *error;
        _captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:&error];
        //add input to capture session
        if ([_captureSession canAddInput:_captureDeviceInput]) {
            [_captureSession addInput:_captureDeviceInput];
        }
        //commit configuration
        [_captureSession commitConfiguration];
        _torchMode = AVCaptureTorchModeOff;
        if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeLocked]) {
            [_captureDevice lockForConfiguration:nil];
            [_captureDevice setFocusMode:AVCaptureFocusModeLocked];
            [_captureDevice unlockForConfiguration];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.captureSession removeInput:self.captureDeviceInput];//Important: 100% crash in iOS<4.1
}

#pragma mark - notification of capture session
- (void)onVideoError:(NSNotification *) notification
{
    [self.captureDevice unlockForConfiguration];
//    NSError *error = [notification.userInfo objectForKey:AVCaptureSessionErrorKey];
//    NSLog(@"WCCCaptureView:ERROR during capture:%@: %@",[error localizedDescription],[error localizedFailureReason]);
}

- (void)onVideoStart:(NSNotification *) notification
{
    NSError *error = nil;
    if ([self.captureDevice lockForConfiguration:&error]) {
        if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            if ([self.captureDevice isFocusPointOfInterestSupported]) {
                [self.captureDevice setFocusPointOfInterest:CGPointMake(0.49f, 0.49f)];
            }
            [self.captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        if ([self.captureDevice isTorchModeSupported:_torchMode]) {
            [self.captureDevice setTorchMode:_torchMode];
        }
    }
}

- (void)onVideoStop:(NSNotification *) notification
{
    [self.captureDevice unlockForConfiguration];
}


#pragma mark - public method
- (void)addCaptureOutput:(AVCaptureOutput *)output
{
    [_captureSession beginConfiguration];
    if ([_captureSession canAddOutput:output]) {
        [_captureSession addOutput:output];
    }
    [_captureSession commitConfiguration];
}

- (void)removeCaptureOutput:(AVCaptureOutput *)output
{
    [_captureSession beginConfiguration];
    [_captureSession removeOutput:output];
    [_captureSession commitConfiguration];
}

@end
