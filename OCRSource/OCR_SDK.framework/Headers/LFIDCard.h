//
//  LFIDCard.h
//  LinkfaceForOCRNew
//
//  Created by linkface on 2019/3/26.
//  Copyright © 2019 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LFIDCardMode)
{
    kIDCardSmart = 0    ,   //身份证正面反面智能检测
    kIDCardFrontal      ,   //身份证正面
    kIDCardBack         ,   //身份证背面
};

typedef NS_ENUM(NSInteger, LFIDCardSide)
{
    LFIDCardSideFront = 1,  //身份证正面
    LFIDCardSideBack,       //身份证背面
};

typedef NS_ENUM(NSInteger, LFIDCardType)
{
    LFIDCardTypeUnknow = 0,    ///< 未知
    LFIDCardTypeNormal,        ///< 正常身份证
    LFIDCardTypeTemp           ///< 临时身份证
};

typedef NS_OPTIONS(uint32_t, LFIDCardItemOption) {
    kIDCardItemAll = 0,                 ///全部包括
    kIDCardItemName = 1<<0,             ///< 姓名
    kIDCardItemSex = 1<<1,              ///< 性别
    kIDCardItemNation = 1<<2,           ///< 民族
    kIDCardItemBirthday = 1<<3,         ///< 生日
    kIDCardItemAddr = 1<<4,             ///< 地址
    kIDCardItemNum = 1<<5,              ///< 身份证号
    kIDCardItemAuthority = 1<<6,        ///< 签发机关
    kIDCardItemTimelimit = 1<<7,        ///< 有效期限
};


@interface LFIDCard : NSObject

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

@property (nonatomic, copy) NSString    *strVersion   ;   //SDK版本号

// Foreground Content
@property (nonatomic, copy) NSString    *strName    ;   //姓名
@property (nonatomic, copy) NSString    *strSex     ;   //性别
@property (nonatomic, copy) NSString    *strNation  ;   //民族
@property (nonatomic, copy) NSString    *strYear    ;   //出生年
@property (nonatomic, copy) NSString    *strMonth   ;   //出生月
@property (nonatomic, copy) NSString    *strDay     ;   //出生日
@property (nonatomic, copy) NSString    *strAddress ;   //住址
@property (nonatomic, copy) NSString    *strID      ;   //公民身份证号

// Background Content
@property (nonatomic, copy) NSString    *strAuthority;   //签发机关
@property (nonatomic, copy) NSString    *strValidity ;   //有效期

// Image of Card & Face
@property (nonatomic, strong) UIImage    *imgOriginCaptured;     //摄像头捕捉到的图像
@property (nonatomic, strong) UIImage    *imgOriginCroped;       //摄像头捕捉到的框内的图像
@property (nonatomic, strong) UIImage    *imgCardDetected    ;   //检测出的卡片图像(裁剪图)
@property (nonatomic, strong) UIImage    *imgCardFace        ;   //检测出的卡片人像

// Image of each Result
@property (nonatomic, strong) UIImage    *imgName    ;   //姓名
@property (nonatomic, strong) UIImage    *imgSex     ;   //性别
@property (nonatomic, strong) UIImage    *imgNation  ;   //民族
@property (nonatomic, strong) UIImage    *imgYear    ;   //出生年
@property (nonatomic, strong) UIImage    *imgMonth   ;   //出生月
@property (nonatomic, strong) UIImage    *imgDay     ;   //出生日
@property (nonatomic, strong) UIImage    *imgAddress ;   //住址
@property (nonatomic, strong) UIImage    *imgID      ;   //公民身份证号
@property (nonatomic, strong) UIImage    *imgAuthority;   //签发机关
@property (nonatomic, strong) UIImage    *imgValidity ;   //有效期

@property (nonatomic, assign) CGRect    rectName    ;   //姓名
@property (nonatomic, assign) CGRect    rectSex     ;   //性别
@property (nonatomic, assign) CGRect    rectNation  ;   //民族
@property (nonatomic, assign) CGRect    rectYear    ;   //出生年
@property (nonatomic, assign) CGRect    rectMonth   ;   //出生月
@property (nonatomic, assign) CGRect    rectDay     ;   //出生日
@property (nonatomic, assign) CGRect    rectAddress ;   //住址
@property (nonatomic, assign) CGRect    rectID      ;   //公民身份证号
@property (nonatomic, assign) CGRect    rectAuthority;   //签发机关
@property (nonatomic, assign) CGRect    rectValidity ;   //有效期

@property (nonatomic, copy) NSString    *strDate   ;   //出生年月日
@property (nonatomic, strong) UIImage    *imgDate    ;   //出生年月日

@property (nonatomic, strong) NSData *encryptedData;   // 加密数据

//身份证类型，（normal：正常拍摄、photocopy：复印件、PS：照片PS、reversion：翻拍、other：其他）
@property (nonatomic, copy)   NSString  *type;
/*! @brief iMode 控制识别身份证哪个面：
 *              0 - kIDCardFrontal   - 正面 ,
 *              1 - kIDCardBack      - 反面,
 *              2 - kIDCardBothSides - 双面识别
 *              3 - kIDCardSmart     - 智能检测 （default）
 */
@property (nonatomic, assign) LFIDCardMode iMode;

@property (nonatomic, assign) BOOL shouldFullCard; //是否卡片完整才返回

// 表示检测到的身份证是那个面
@property (nonatomic) LFIDCardSide side;

/*! @brief bFaceExist 是否存在人像
 */
@property (nonatomic, assign) BOOL bFaceExist;

/*! @brief bDebug 调试开关(控制NSLog的输出)
 */
@property (nonatomic, assign) BOOL bDebug;
/*
  是否开启身份证类型检测
*/
@property(nonatomic,assign)BOOL returnType;


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
/*! @brief recognizeCard 接口提供身份证检测和识别功能，用于图片输入
 *
 * 上传图片最大大小 5MB,图片分辨率最大支持 3000px*3000px，过小分辨率可能导致识别不出小的文字
 * @param imageCard 上传的图片
 * @return 检测识别结果的状态。
 *          -2 : 无图像
 *          -1 : 检测不成功
 *          -3 : 检测成功, Alignment 不成功 (v3.4)
 *           0 : 检测成功，识别不成功
 *           1 : 识别有误，校验不成功
 *           2 : 识别成功
 *       当识别成功后，离线版请在上述成员变量strName, ... , strAuthority 中获取识别结果 在线版返回加密数据 encryptedData
 *       也可调用下面的【getFrontalInfo 】函数获取识别结果
 *       也可调用下面的【getBackSideInfo】函数获取识别结果
 */
- (int)recognizeCard:(UIImage *)imageCard complete:(void (^)(BOOL success))complete;
/*! @brief recognizeCardWithBuffer 接口提供身份证检测和识别功能，用于视频帧数据输入
 *
 * @param pImageCard 视频帧数据，格式是BGRA格式
 * @param iWidth    视频帧图像的宽度
 * @param iHeight   视频帧图像的高度
 * @return 检测识别结果的状态。
 *          -2 : 无图像
 *          -1 : 检测不成功
 *          -3 : 检测成功, Alignment 不成功 (v3.4)
 *           0 : 检测成功，识别不成功
 *           1 : 识别有误，校验不成功
 *           2 : 识别成功
 *       当识别成功后，离线版请在上述成员变量strName, ... , strAuthority 中获取识别结果 在线版返回加密数据 encryptedData
 *       也可调用下面的【getFrontalInfo 】函数获取识别结果的正面文字信息
 *       也可调用下面的【getBackSideInfo】函数获取识别结果的背面文字信息
 */
- (int)recognizeCardWithBuffer:(unsigned char *)pImageCard width:(int)iWidth height:(int)iHeight;

- (int)recognizeCardWithBuffer:(CVPixelBufferRef)pixelBuffer;



- (void)setRecognizeItemsOptions:(LFIDCardItemOption)option;

// 获取SDK版本号
+ (NSString *)getSDKVersion;


@end

NS_ASSUME_NONNULL_END
