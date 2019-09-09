//
//  LFLivenessCommon.h
//  LFLivenessController
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#ifndef LFLivenessCommon_h
#define LFLivenessCommon_h


#define kSTColorWithRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 \
green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0 \
blue:((float)(rgbValue & 0xFF)) / 255.0 alpha:1.0]

#define kLFScreenWidth [UIScreen mainScreen].bounds.size.width
#define kLFScreenHeight [UIScreen mainScreen].bounds.size.height

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
#define LFNavigationBarHeightMargin  (isFullScreen ? 24.f : 0.f)
#define LFTabbarSafeBottomMargin         (isFullScreen ? 34.f : 0.f)

#endif /* LFLivenessCommon_h */
