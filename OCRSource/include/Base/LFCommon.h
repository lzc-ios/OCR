//
//  LFCommon.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#ifndef deepid_Common_h
#define deepid_Common_h

//#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

#define KISIphoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define SCREEN_HEIGHT [[UIScreen mainScreen]bounds].size.height
#define SCREEN_WIDTH  [[UIScreen mainScreen]bounds].size.width
#define MAINSCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define MAINSCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define CAPTURE_SESSION_QUALITY 2   // 0:640*480 vertical, 1:640*480 horizontal 2:1280*720 vertical, 3:1280:720 horizontal 4:1280*720 horizontal at left-up corner

// iPhone X
#define LFiPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
// iPhoneXR
#define LFIPHONE_Xr ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size): NO)

//iPhoneXs Max
#define LFIPHONE_Xs_Max ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) : NO)

//异性全面屏
#define   isFullScreen    (LFIPHONE_Xr || LFIPHONE_Xs_Max || LFiPhoneX)

#define  LFStatusBarHeight      (isFullScreen ? 44.f : 20.f)
#define kTabBarHeight         (isFullScreen ? (49.f+34.f) : 49.f)//83
#define LFStatusBarAndNavigationBarHeight  (isFullScreen ? 88.f : 64.f)
#define LFTabbarSafeBottomMargin         (isFullScreen ? 34.f : 0.f)

#define WINDOW_WIDTH 480
#define WINDOW_HEIGHT 720
#define WINDOW_XOFFSET 400
#define WINDOW_YOFFSET 0

#define CHECK_IF_FOCUSED_FIRST TRUE

#define warpNullString(a) if (!(a)) {(a) = @"";}

#define faceCaptureControllerTag 10001

#define MASK_WINDOW_H (CGRectMake(40, 440, 640, 400))
#define MASK_WINDOW_V (CGRectMake(110, 240, 500, 800))

#define MASK_BANKCARD_WINDOW_H (CGRectMake(80, 465, 560, 350))
#define MASK_BANKCARD_WINDOW_V (CGRectMake(110, 240, 500, 800))

#define VIEDO_WIDTH (720)
#define VIDEO_HEIGHT (1280)

#endif
