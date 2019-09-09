//
//  LFLivenessEnumType.h
//  LFLivenessDetector
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#ifndef LFLivenessEnumType_h
#define LFLivenessEnumType_h


/**
 *  活体检测失败类型
 */
typedef NS_ENUM(NSInteger, LivefaceErrorType) {
    
    /**
     *  算法SDK初始化失败
     */
    LIVENESS_INIT_FAILD = 0,
    
    /**
     *  相机权限获取失败
     */
    LIVENESS_CAMERA_ERROR,
    
    
    /**
     *  人脸变更
     */
    LIVENESS_FACE_CHANGED,
    
    /**
     *  检测超时
     */
    LIVENESS_TIMEOUT,
    
    /**
     *  应用即将被挂起
     */
    LIVENESS_WILL_RESIGN_ACTIVE,
    
    /**
     *  内部错误
     */
    LIVENESS_INTERNAL_ERROR,
    
    /**
     *  包名错误
     */
    LIVENESS_BUNDLEID_ERROR,
    
    /**
     *  时间过期
     */
    LIVENESS_AUTH_EXPIRE,
    /**
     * license文件不合法
     */
    LIVENESS_LICENSE_ERROR,
    /**
     * 模型文件过期
     */
    LINENESS_MODEL_EXPIRE,
    /**
     *模型文件路径错误
     */
    LINENESS_MODEL_SOURCE,
    /**
     * 其他错误
     */
    LINENESS_OTHER_ERROR
    
};

/**
 *  检测模块类型
 */
typedef NS_ENUM(NSInteger, LivefaceDetectionType) {
    
    /**
     *  未定义类型
     */
    LIVE_NONE = 0,
    
    /**
     *  眨眼检测
     */
    LIVE_BLINK,
    
    /**
     *  上下点头检测
     */
    LIVE_NOD,
    
    /**
     *  张嘴检测
     */
    LIVE_MOUTH,
    
    /**
     *  左右转头检测
     */
    LIVE_YAW
};


/**
 *  人脸方向
 */
typedef NS_ENUM(NSUInteger, LivefaceOrientation) {
    /**
     *  人脸向上，即人脸朝向正常
     */
    LIVE_FACE_UP = 0,
    /**
     *  人脸向左，即人脸被逆时针旋转了90度
     */
    LIVE_FACE_LEFT = 1,
    /**
     *  人脸向下，即人脸被逆时针旋转了180度
     */
    LIVE_FACE_DOWN = 2,
    /**
     *  人脸向右，即人脸被逆时针旋转了270度
     */
    LIVE_FACE_RIGHT = 3
};


/**
 *  输出方案
 */
typedef NS_ENUM(NSUInteger, LivefaceOutputType) {
    
    /**
     *  单图方案
     */
    LIVE_OUTPUT_SINGLE_IMAGE,
    
    /**
     *  多图方案
     */
    LIVE_OUTPUT_MULTI_IMAGE,
    
    /**
     *  低质量视频方案
     */
    LIVE_OUTPUT_LOW_QUALITY_VIDEO,
    
    /**
     *  高质量视频方案
     */
    LIVE_OUTPUT_HIGH_QUALITY_VIDEO
};


/**
 *  活体检测复杂度
 */
typedef NS_ENUM(NSUInteger, LivefaceComplexity) {
    
    /**
     *  简单, 人脸变更时不会回调 LIVENESS_FACE_CHANGED 错误, 活体阈值低
     */
    LIVE_COMPLEXITY_EASY,
    
    /**
     *  一般, 人脸变更时会回调 LIVENESS_FACE_CHANGED 错误, 活体阈值较低
     */
    LIVE_COMPLEXITY_NORMAL,
    
    /**
     *  较难, 人脸变更时会回调 LIVENESS_FACE_CHANGED 错误, 活体阈较高
     */
    LIVE_COMPLEXITY_HARD,
    
    /**
     *  困难, 人脸变更时会回调 LIVENESS_FACE_CHANGED 错误, 活体阈值高
     */
    LIVE_COMPLEXITY_HELL
};


#endif /* LFLivenessEnumType_h */
