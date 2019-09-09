//
//  LFIDCardPhotoViewController.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFCapturePhotoViewController.h"
#import "LFIDCardScannerController.h"

@interface LFIDCardPhotoViewController : LFCapturePhotoViewController

@property (nonatomic, copy) NSString *appID;
@property(nonatomic,copy) NSString *appSecret;
// 拍照
@property(nonatomic,assign)NSInteger isAuto;
// 横竖卡
@property(nonatomic,assign)BOOL isVertical;
// bDebug
@property(nonatomic,assign)BOOL bDebug;
//是否开启身份证类型检测
@property(nonatomic,assign)BOOL returnType;


@property (nonatomic, weak) id<LFIDCardScannerControllerDelegate> delegate;

- (instancetype)initWithLicenesePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard modelPath:(NSString *)modelPath extraPath:(NSString *)extraPath iMode:(LFIDCardMode)iMode;

@end
