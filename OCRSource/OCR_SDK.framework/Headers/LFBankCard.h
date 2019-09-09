//
//  LFBankCard.h
//  LinkfaceForOCRNew
//
//  Created by linkface on 2019/3/26.
//  Copyright © 2019 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface LFBankCard : NSObject

// appID
@property(nonatomic,copy)NSString *appID;
// appSecret
@property(nonatomic,copy)NSString *appSecret;
// 拍照
@property(nonatomic,assign)NSInteger isAuto;
// 横竖卡
@property(nonatomic,assign)NSInteger isVertical;
// 亮度值，默认128
@property(nonatomic,assign)NSInteger brightNumber;
// 模糊度
@property(nonatomic,assign)float fuzzyNumber;

@property (nonatomic, strong) UIImage *imgOriginCaptured;       // 摄像头捕捉到的图像
@property (nonatomic, strong) UIImage *imgOriginCroped;         // 摄像头捕捉到的框内的图像
@property (nonatomic, strong) UIImage *imgCardDetected;         // 检测出的卡片图像(裁剪图)
@property (nonatomic, strong) UIImage *imgCardNumber;           // 检测出的卡片号码图片

@property (nonatomic, copy) NSString *strVersion;                       // SDK版本号
@property (nonatomic, copy) NSString *strNumber;                        // 卡号
@property (nonatomic, copy) NSString *strBankName;                      // 银行名称
@property (nonatomic, copy) NSString *strBankIdentificationNumber;      // 银行编号
@property (nonatomic, copy) NSString *strCardName;                      // 卡片名称
@property (nonatomic, copy) NSString *strCardType;                      // 卡片类型
@property (nonatomic, copy) NSString *strSpacedNumber;                  // 带空格的卡号

@property (nonatomic, strong, readonly) NSData *encryptedData;          // 加密数据

/*! @brief bDebug 调试开关(控制NSLog的输出)
 */
@property (nonatomic, assign) BOOL bDebug;
@property (nonatomic, assign) BOOL isScanVerticalCard; // 是否扫描竖卡
@property (nonatomic, assign) BOOL shouldFullCard; //是否卡片完整才返回


/*!
 * @brief LFBankCard 初始化函数
 *
 * 在使用银行卡识别功能之前调用, 可以初始化一次，多次进行银行卡识别。
 * @param modelPath bankcard路径
 * @param extraPath bankextra路径
 * @return 如果数据完整，初始化成功，返回 LFBankCard 对象；否则返回 nil 。
 */
- (instancetype)initWithModelPath:(NSString *)modelPath extraPath:(NSString *)extraPath;

- (instancetype)init NS_UNAVAILABLE;

/*! @brief recognizeCard 接口提供银行卡检测和识别功能，用于图片输入
 *
 * 上传图片最大大小 5MB,图片分辨率最大支持 3000px*3000px，过小分辨率可能导致识别不出小的文字
 * @param imageCard 上传的图片
 * @return 检测识别结果的状态。
 *           0 : 识别失败
 *           1 : 识别成功
 *       当识别成功后，离线版请在上述成员变量strNumber, numberType 中获取识别结果 在线版返回加密数据 encryptedData
 */
- (int)recognizeCard:(UIImage *)imageCard Complete:(void(^)(BOOL success))complete;

/*! @brief recognizeCardWithBuffer 接口提供银行卡检测和识别功能，用于视频帧数据输入
 *
 * @param pImageCard 视频帧数据，格式是BGRA格式
 * @param iWidth    视频帧图像的宽度
 * @param iHeight   视频帧图像的高度
 * @return 检测识别结果的状态。
 *           0 : 识别失败
 *           1 : 识别成功
 *       当识别成功后，在线版请在上述成员变量strNumber, numberType 中获取识别结果 离线版返回加密数据 encryptedData
 */
- (int)recognizeCardWithBuffer:(unsigned char *)pImageCard width:(int)iWidth height:(int)iHeight ;

// 获取SDK版本号
+ (NSString *)getSDKVersion;


@end

NS_ASSUME_NONNULL_END
