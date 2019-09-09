//
//  LFCapture.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVCaptureSession,AVCaptureDeviceInput,AVCaptureDevice,AVCaptureOutput;

@interface LFCapture : NSObject

@property(nonatomic, strong, readonly) AVCaptureSession *captureSession;
@property(nonatomic, strong, readonly) AVCaptureDevice *captureDevice;
@property(nonatomic, strong, readonly) AVCaptureDeviceInput *captureDeviceInput;
@property(nonatomic, strong, readonly) AVCaptureMovieFileOutput *captureMovieFileOutput;

@property(nonatomic, assign) AVCaptureTorchMode         torchMode;
@property(nonatomic, assign) AVCaptureDevicePosition    devicePosition;

- (void)removeCaptureOutput:(AVCaptureOutput *)output;
- (void)addCaptureOutput:(AVCaptureOutput *)output;

@end
