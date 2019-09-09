//
//  LFCaptureReaderDelegate.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class LFCaptureReader;
@class LFIDCard;

@protocol LFCaptureReaderDelegate <NSObject>

@optional

- (void)captureReader:(LFCaptureReader *)reader didSnapshotInProgress:(UIImage *)image ;

- (void)captureReader:(LFCaptureReader *)reader getCardResult:(NSObject *)cardResult;

//Cancel case
- (void)captureReader:(LFCaptureReader *)reader didCancel:(NSString *)strMessage;

- (void)scannerException:(NSException*)e ;  // catch the exception

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

@end
