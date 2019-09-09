//
//  LFAlertView.h
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LFAlertViewDelegate;

@interface LFAlertView : UIView

- (LFAlertView *)initWithTitle:(NSString *)title delegate:(id <LFAlertViewDelegate> )delegate;

- (void)showOnView:(UIView *)view;

@end


@protocol LFAlertViewDelegate <NSObject>

- (void)tipView:(LFAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end
