//
//  LFCaptureDelegate
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LFCaptureDelegate <NSObject>

@optional
//每过一段时间 获取屏幕快照 需要设置snapshotSeconds
- (void)getSnapshot:(nullable UIImage *)imgSnap;
//切换横卡竖卡
- (void)changeScanDirection:(nullable UIButton *)button;
//出错
- (void)scannerException:(nullable NSException*)e;  // catch the exception

@required
//取消识别
- (void)didCancel;

//超时自动取消
- (void)autoCancel;
@end
