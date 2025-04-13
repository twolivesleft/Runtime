//
//  CodeaOutputDelegate.h
//  Runtime
//
//  Created by Sim Saens on 22/7/2024.
//  Copyright © 2024 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CodeaViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol CodeaOutputDelegate

- (void) codea:(CodeaViewController*)codea didPrintOutput:(NSString*)text;
- (void) codea:(CodeaViewController*)codea didPrintWarning:(NSString*)text;
- (void) codea:(CodeaViewController*)codea didPrintError:(NSString*)text;
- (void) codeaDidClearOutput:(CodeaViewController*)codea;

@end

NS_ASSUME_NONNULL_END
