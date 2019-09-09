//
//  LFBankCardPhotoViewController.m
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFBankCardPhotoViewController.h"
#import <Photos/PHPhotoLibrary.h>
#import "LFImageClipViewController.h"
#import "SVProgressHUD.h"
static const CGFloat kCompressionQuality = 0.7;

@interface LFBankCardPhotoViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, LFImageClipDelegate>

@property (nonatomic, strong) UIButton *changeScanDirectionButton;

@property (nonatomic, strong) LFBankCard *bankCard;

@end

@implementation LFBankCardPhotoViewController

- (instancetype)initWithLicensePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard {
    return [self initWithLicenesePath:licensePath shouldFullCard:shouldFullCard modelPath:nil extraPath:nil];
}

- (instancetype)initWithLicenesePath:(NSString *)licensePath shouldFullCard:(BOOL)shouldFullCard modelPath:(NSString *)modelPath extraPath:(NSString *)extraPath {
    LFBankCardPhotoViewController *vc = [[LFBankCardPhotoViewController alloc] init];
    vc.bankCard = [[LFBankCard alloc] initWithModelPath:modelPath extraPath:extraPath];
    vc.bankCard.shouldFullCard = shouldFullCard;
    return vc;
}

- (UIButton *)changeScanDirectionButton {
    if (!_changeScanDirectionButton) {
        _changeScanDirectionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
        UIImage *imageBtn = [UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"scan_horizontal" ofType:@"png"]];
        
        _changeScanDirectionButton.tag = 0;
        switch (self.captureOrientation) {
            case AVCaptureVideoOrientationPortrait:
                _changeScanDirectionButton.frame = CGRectMake(SCREEN_WIDTH - 40 - 22, SCREEN_HEIGHT - 40 - 20, 40, 40);
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
                _changeScanDirectionButton.frame = CGRectMake(22, LFStatusBarHeight, 40, 40);
                break;
            case AVCaptureVideoOrientationLandscapeRight:
                _changeScanDirectionButton.frame = CGRectMake(SCREEN_WIDTH - 40 - 22, SCREEN_HEIGHT - 40 - 20, 40, 40);
                break;
            default:
                _changeScanDirectionButton.frame = CGRectMake(22, LFStatusBarHeight, 40, 40);
                break;
        }
        
        _changeScanDirectionButton.transform = self.interfaceTransform;
        [_changeScanDirectionButton setImage:imageBtn forState:UIControlStateNormal];
        [_changeScanDirectionButton addTarget:self action:@selector(changeScanDirection) forControlEvents:UIControlEventTouchUpInside];
    }
    return _changeScanDirectionButton;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedErrorNote:) name:@"PostedError" object:nil];

    [self.view addSubview:self.changeScanDirectionButton];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 200) *0.5, LFStatusBarHeight, 200, 40)];
    titleLabel.text = @"请拍摄银行卡";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:20];
    titleLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:titleLabel];

    [self.readerView setLabelText:@"请将银行卡边缘与取景框边缘重合"];
    self.bankCard.appID = self.appID;
    self.bankCard.appSecret = self.appSecret;
    self.bankCard.isAuto = self.isAuto;
    self.bankCard.bDebug = self.bDebug;
    // Do any additional setup after loading the view.
}

- (void)setIsScanVerticalCard:(BOOL)isScanVerticalCard {
    [super setIsScanVerticalCard:isScanVerticalCard];
//    self.bankCard.isScanVerticalCard = isScanVerticalCard;
}

- (void)changeScanDirection {
    
    self.isScanVerticalCard = !self.isScanVerticalCard;
    [self.readerView changeScanWindowDirection:self.isScanVerticalCard];
    
    NSBundle *resoureceBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"OCR_SDK_Resource" withExtension:@"bundle"]];
    if (self.isScanVerticalCard) {
        self.changeScanDirectionButton.tag = 1;
        [self.changeScanDirectionButton setImage:[UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"scan_vertical" ofType:@"png"]] forState:UIControlStateNormal];
        self.bankCard.isVertical = 1;
    }else {
        self.changeScanDirectionButton.tag = 0;
        [self.changeScanDirectionButton setImage:[UIImage imageWithContentsOfFile:[resoureceBundle pathForResource:@"scan_horizontal" ofType:@"png"]] forState:UIControlStateNormal];
        self.bankCard.isVertical = 0;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleImage:(UIImage *)image {

    [SVProgressHUD show];
    [self.bankCard recognizeCard:image Complete:^(BOOL success) {
        [SVProgressHUD dismiss];
        if (success){
            if (self.delegate && [self.delegate respondsToSelector:@selector(getCardResult:)]) {
                [self.bankCard setImgOriginCroped:image];
                [self.delegate getCardResult:self.bankCard];
            } else if (self.delegate && [self.delegate respondsToSelector:@selector(getCardImage:withCardInfo:)]) {
                [self.delegate getCardImage:image withCardInfo:self.bankCard];
            }
        }else{
            [SVProgressHUD showWithStatus:@"识别失败！"];
        }
    }];
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
    int isIdentify = [self.bankCard recognizeCard:editedImage Complete:^(BOOL success) {
        if (success){
            // 设置取景框中的图片
            self.bankCard.imgOriginCroped = editedImage;
            //识别成功
            if (self.delegate && [self.delegate respondsToSelector:@selector(getCardResult:)]) {
                [self.delegate getCardResult:self.bankCard];
            } else if (self.delegate && [self.delegate respondsToSelector:@selector(getCardImage:withCardInfo:)]) {
                [self.delegate getCardImage:editedImage withCardInfo:self.bankCard];
            }
        }else{
            [SVProgressHUD showWithStatus:@"识别失败！"];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
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
