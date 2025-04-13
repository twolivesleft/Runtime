//
//  CodeaRuntimeDelegate.h
//  Runtime
//
//  Created by Sim Saens on 22/7/2024.
//  Copyright © 2024 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CodeaViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol CodeaRuntimeDelegate

- (void) codeaDidSetup:(CodeaViewController*)codea;
- (void) codea:(CodeaViewController*)codea didPause:(BOOL)didPause;
- (void) codeaRestarted:(CodeaViewController*)codea;
- (void) codeaWillClose:(CodeaViewController*)codea;

@end

NS_ASSUME_NONNULL_END
