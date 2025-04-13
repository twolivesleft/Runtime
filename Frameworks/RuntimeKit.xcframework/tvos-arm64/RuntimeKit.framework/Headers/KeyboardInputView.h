//
//  KeyboardInputView.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 14/01/12.
//  Copyright (c) 2012 Two Lives Left. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KeyboardInputView;

@protocol KeyboardInputViewDelegate <NSObject>

- (void) keyboardInputView:(KeyboardInputView*)view willInsertText:(NSString*)text;

@end

@interface KeyboardInputView : UIView<UITextViewDelegate>
{
    UITextView *hiddenTextView;
}

@property (assign, nonatomic) BOOL active;
@property (weak, nonatomic) id<KeyboardInputViewDelegate> delegate;
@property (weak, readonly, nonatomic) NSString *currentText;

@end
