//
//  LFIDCardMaskView.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "LFCommon.h"
#import "LFCaptureMaskView.h"

//WINDOW TYPE 1
//#if CAPTURE_SESSION_QUALITY == 2
//#define WINDOW_WIDTH 480
//#define WINDOW_HEIGHT 640
//#define WINDOW_XOFFSET 400
//#define WINDOW_YOFFSET 40
//#elif CAPTURE_SESSION_QUALITY == 3
//#define WINDOW_WIDTH 640
//#define WINDOW_HEIGHT 480
//#define WINDOW_XOFFSET 320
//#define WINDOW_YOFFSET 120

#define PIXEL_COMPONENT_NUM 4
//#if CAPTURE_SESSION_QUALITY == 2
//#endif

@interface LFIDCardMaskView : LFCaptureMaskView

- (void)setLabel:(UILabel *)label;

- (void)moveWindowDeltaY:(int)iDeltaY;  //  iDeltaY == 0 in center , < 0 move up, > 0 move down

@end
