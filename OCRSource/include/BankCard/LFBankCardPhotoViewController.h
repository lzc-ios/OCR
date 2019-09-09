//
//  LFBankCardPhotoViewController.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFCapturePhotoViewController.h"
#import "LFBankCardScannerController.h"

@interface LFBankCardPhotoViewController : LFCapturePhotoViewController

@property (nonatomic, weak) id <LFBankCardScannerControllerDelegate> delegate;
@property (nonatomic, copy) NSString *appID;
@property(nonatomic,copy) NSString *appSecret;
// 拍照
@property(nonatomic,assign)NSInteger isAuto;
// 横竖卡
@property(nonatomic,assign)NSInteger isVertical;
// BUG
@property(nonatomic,assign)BOOL bDebug;

@end
