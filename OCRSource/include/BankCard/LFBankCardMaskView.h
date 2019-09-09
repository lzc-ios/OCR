//
//  LFBankCardMaskView.h
//  Linkface
//
//  Copyright © 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFCommon.h"
#import "LFCaptureMaskView.h"


#define PIXEL_COMPONENT_NUM 3

@interface LFBankCardMaskView : LFCaptureMaskView

- (void)setLabelText: (NSString *)text;

- (void)moveWindowDeltaY:(int)iDeltaY;  //  iDeltaY == 0 in center , < 0 move up, > 0 move down

- (void)changeScanWindowDirection:(BOOL)isVertical;

@end
