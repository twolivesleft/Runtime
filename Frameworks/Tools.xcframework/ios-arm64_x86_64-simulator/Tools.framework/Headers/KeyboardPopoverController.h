//
//  SimplePopoverController.h
//  Tools
//
//  Created by Simeon on 27/12/12.
//  Copyright (c) 2012 Two Lives Left. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KeyboardPopoverController;

@protocol KeyboardPopoverDelegate <NSObject>

- (void) keyboardPopoverDidDismissPopover:(KeyboardPopoverController*)controller;

@end

@interface KeyboardPopoverController : UIViewController

@property (nonatomic, weak) id<KeyboardPopoverDelegate> delegate;

- (id) initWithContentViewController:(UIViewController*)controller;

- (void) setKeyboardAppearance:(UIKeyboardAppearance)appearance;

- (void) presentPopoverFromPoint:(CGPoint)point inView:(UIView*)view;
- (void) dismissPopoverAnimated:(BOOL)animated;

@end
