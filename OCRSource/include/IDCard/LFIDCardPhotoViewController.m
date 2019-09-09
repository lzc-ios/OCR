//
//  LFIDCardPhotoViewController.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFIDCardPhotoViewController.h"
#import <Photos/PHPhotoLibrary.h>
#import "LFImageClipViewController.h"
#import <OCR_SDK/OCR_SDK.h>
#import "SVProgressHUD.h"

static const CGFloat kCompressionQuality = 0.7;

@interface LFIDCardPhotoViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, LFImageClipDelegate>

//@property (nonatomic, strong) UIButton *changeScanDirectionButton;

@property (nonatomic, strong) LFIDCard *idCard;

@end

@implementation LFIDCardPhotoViewController

- (instancetype)initWithLicensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard {
    return [self initWithLicenesePath:licensePath shouldFullCard:shouldFullCard modelPath:nil extraPath:nil];
}

- (instancetype)initWithLicenesePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard modelPath:(NSString *)modelPath extraPath:(NSString *)extraPath {
    return [self initWithLicenesePath:licensePath shouldFullCard:shouldFullCard modelPath:modelPath extraPath:extraPath iMode:kIDCardSmart];
}

- (instancetype)initWithLicenesePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard modelPath:(NSString *)modelPath extraPath:(NSString *)extraPath iMode:(LFIDCardMode)iMode {
    
    LFIDCardPhotoViewController *vc = [[LFIDCardPhotoViewController alloc] init];
    
    LFIDCard *idcard = [[LFIDCard alloc] initWithModelPath:modelPath extraPath:extraPath];
    if (idcard) {
        idcard.shouldFullCard = shouldFullCard;
        idcard.iMode = kIDCardSmart;
    }
    vc.idCard = idcard;
    vc.idCard.iMode = iMode;
    vc.idCard.shouldFullCard = shouldFullCard;
    return vc;
}

//- (UIButton *)changeScanDirectionButton {
//    if (!_changeScanDirectionButton) {
//        _changeScanDirectionButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
//        UIImage *imageBtn = [UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"scan_horizontal" ofType:@"png"]];
//
//        _changeScanDirectionButton.tag = 0;
//        switch (self.captureOrientation) {
//            case AVCaptureVideoOrientationPortrait:
//                _changeScanDirectionButton.frame = CGRectMake(SCREEN_WIDTH - 40 - 22, SCREEN_HEIGHT - 40 - 20, 40, 40);
//                break;
//            case AVCaptureVideoOrientationLandscapeLeft:
//                _changeScanDirectionButton.frame = CGRectMake(22, 20, 40, 40);
//                break;
//            case AVCaptureVideoOrientationLandscapeRight:
//                _changeScanDirectionButton.frame = CGRectMake(SCREEN_WIDTH - 40 - 22, SCREEN_HEIGHT - 40 - 20, 40, 40);
//                break;
//            default:
//                _changeScanDirectionButton.frame = CGRectMake(22, 20, 40, 40);
//                break;
//        }
//
//        _changeScanDirectionButton.transform = self.interfaceTransform;
//        [_changeScanDirectionButton setImage:imageBtn forState:UIControlStateNormal];
//        [_changeScanDirectionButton addTarget:self action:@selector(changeScanDirection) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _changeScanDirectionButton;
//}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedErrorNote:) name:@"PostedError" object:nil];
    
//    [self.view addSubview:self.changeScanDirectionButton];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 200) *0.5, LFStatusBarHeight, 200, 40)];
    titleLabel.text = @"请拍摄身份证";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:20];
    titleLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:titleLabel];
    
    [self.readerView setLabelText:@"请将身份证边缘与取景框边缘重合"];
    self.idCard.appID = self.appID;
    self.idCard.appSecret = self.appSecret;
    self.idCard.isAuto = self.isAuto;
    self.idCard.bDebug = self.bDebug;
    self.idCard.returnType = self.returnType;
    // Do any additional setup after loading the view.
}


//- (void)changeScanDirection {
//
//    self.isScanVerticalCard = !self.isScanVerticalCard;
//    [self.readerView changeScanWindowDirection:self.isScanVerticalCard];
//
//    NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
//    if (self.isScanVerticalCard) {
//        self.changeScanDirectionButton.tag = 1;
//        [self.changeScanDirectionButton setImage:[UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"scan_vertical" ofType:@"png"]] forState:UIControlStateNormal];
//
//    }else {
//        self.changeScanDirectionButton.tag = 0;
//        [self.changeScanDirectionButton setImage:[UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"scan_horizontal" ofType:@"png"]] forState:UIControlStateNormal];
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleImage:(UIImage *)image {
   
    
//    [self.idCard recognizeCard:image];

    [SVProgressHUD show];
//    int isIdentify = [self.idCard recognizeCard:image];
    [self.idCard recognizeCard:image complete:^(BOOL success) {
        [SVProgressHUD dismiss];
        if (success){
            if (self.delegate && [self.delegate respondsToSelector:@selector(getCardResult:)]) {
                [self.idCard setImgOriginCroped:image];
                [self.delegate getCardResult:self.idCard];
            } else if (self.delegate && [self.delegate respondsToSelector:@selector(getCard:withInformation:)]) {
                [self.delegate getCard:image withInformation:self.idCard];
            }
        }else{
            [SVProgressHUD showWithStatus:@"识别失败！"];
        }
    }];
//    if (isIdentify == 2) {
//        //识别成功
//        if (self.delegate && [self.delegate respondsToSelector:@selector(getCardResult:)]) {
//            [self.delegate getCardResult:self.idCard];
//        } else if (self.delegate && [self.delegate respondsToSelector:@selector(getCard:withInformation:)]) {
//            [self.delegate getCard:image withInformation:self.idCard];
//        }
//    } else {
//        [self receivedError:0];
//    }
}

- (void)receivedErrorNote:(NSNotification *)notification {
    NSInteger code = [(NSNumber *)[notification object] integerValue];
    [self receivedError:code];
}

- (void)showPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]){
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.navigationBar.tintColor = [UIColor blackColor];
        imagePickerController.navigationBar.barStyle = UIBarStyleBlack;
        
        imagePickerController.navigationBar.translucent = YES;
        imagePickerController.sourceType = sourceType;
        if (imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera) {
            imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        }
        imagePickerController.mediaTypes = [NSArray arrayWithObjects: @"public.image", nil];
        imagePickerController.delegate = self;
        //        imagePickerController.allowsEditing = self.allowsEditing;
        //        if (cameraDevice == UIImagePickerControllerSourceTypeCamera) imagePickerController.cameraDevice = cameraDevice;
        
        [self presentViewController:imagePickerController animated:YES completion:nil];
    } else {
        //        [SVProgressHUD showErrorWithStatus:@"您的设备不支持"];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *chosenImage = nil;
    chosenImage = info[UIImagePickerControllerOriginalImage];
    chosenImage = [UIImage imageWithData:UIImageJPEGRepresentation(chosenImage, kCompressionQuality)];
    
    //    [self dismissAnimated:NO];
    
    LFImageClipViewController *imgCropperVC = nil;
    
    imgCropperVC = [[LFImageClipViewController alloc] initWithImage:chosenImage cropFrame:self.readerView.windowFrame limitScaleRatio:3.0 captureOrientation:self.captureOrientation];
    
    imgCropperVC.delegate = self;
    
    [picker pushViewController:imgCropperVC animated:YES];
}

- (void)imageCropper:(LFImageClipViewController *)clipViewController didFinished:(UIImage *)editedImage {
    
    [self.idCard recognizeCard:editedImage complete:^(BOOL success) {
        if (success){
            // 设置取景框中的图片
            self.idCard.imgOriginCroped = editedImage;
            //识别成功
            if (self.delegate && [self.delegate respondsToSelector:@selector(getCardResult:)]) {
                [self.delegate getCardResult:self.idCard];
            } else if (self.delegate && [self.delegate respondsToSelector:@selector(getCard:withInformation:)]) {
                [self.delegate getCard:editedImage withInformation:self.idCard];
            }
        }else{
            [self receivedError:0];
        }
    }];
//    [self.idCard recognizeCard:editedImage];
//    int isIdentify = [self.idCard recognizeCard:editedImage];
//    if (isIdentify == 2) {
//        //识别成功
//        if (self.delegate && [self.delegate respondsToSelector:@selector(getCardResult:)]) {
//            [self.delegate getCardResult:self.idCard];
//        } else if (self.delegate && [self.delegate respondsToSelector:@selector(getCard:withInformation:)]) {
//            [self.delegate getCard:editedImage withInformation:self.idCard];
//        }
//    } else {
//        [self receivedError:0];
//    }
}

- (void)imageCropperDidCancel:(LFImageClipViewController *)clipViewController {
    
    [clipViewController.navigationController popViewControllerAnimated:NO];
}

- (void)receivedError:(NSInteger)code {
    if ([self.delegate respondsToSelector:@selector(getError:)]) {
        [self.delegate getError:code];
    }
}

- (void)didCancel {
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(didCancel)])
    {
        [self.delegate didCancel];
        return;
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
