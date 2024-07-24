//
//  CodeaAddon.h
//  Runtime
//
//  Created by Simeon on 5/04/13.
//  Copyright (c) 2013 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ThreadedRuntimeViewController;
struct lua_State;

@protocol CodeaAddon <NSObject>

//For registering your custom functions and libraries
- (void) codea:(ThreadedRuntimeViewController*)controller didCreateLuaState:(struct lua_State*)L isValidating:(BOOL)validating;

@optional

//For clean up (if necessary)
- (void) codea:(ThreadedRuntimeViewController*)controller willCloseLuaState:(struct lua_State*)L;

//Handling changes to the viewer state (if necessary)
- (void) codea:(ThreadedRuntimeViewController*)controller didPause:(BOOL)pause;

//The reset button is pressed, this will cause:
//  willCloseCodeaLuaState and didCreateCodeaLuaState to be called again in sequence
- (void) codeaWillRestart:(ThreadedRuntimeViewController*)controller;

//Called each frame update
- (void) codeaWillDrawFrame:(ThreadedRuntimeViewController*)controller withDelta:(CGFloat)deltaTime;

//Called after initial setup
- (void) codeaDidFinishSetup:(ThreadedRuntimeViewController*)controller;

//Called when the addon is registered
- (void) codeaDidRegisterAddon:(ThreadedRuntimeViewController*)controller;

@end

NS_ASSUME_NONNULL_END
