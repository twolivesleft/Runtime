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

/// Called when the Lua state is first created. For registering your custom functions and libraries
/// - Parameters:
///   - controller: Runtime controller
///   - L: Newly created Lua state
///   - validating: Whether the state is being created to simply validate the current project
- (void) codea:(ThreadedRuntimeViewController*)controller didCreateLuaState:(struct lua_State*)L isValidating:(BOOL)validating;

@optional

/// Called just prior to the runtime being closed
/// - Parameters:
///   - controller: Runtime controller
///   - L: Lua state about to be closed
- (void) codea:(ThreadedRuntimeViewController*)controller willCloseLuaState:(struct lua_State*)L;

/// Handling changes to the viewer state
/// - Parameters:
///   - controller: Runtime controller
///   - pause: Whether the runtime is paused or unpaused
- (void) codea:(ThreadedRuntimeViewController*)controller didPause:(BOOL)pause;

/// The reset button is pressed, this will cause:
/// willCloseCodeaLuaState and didCreateCodeaLuaState to be called again in sequence
/// - Parameter controller: Runtime controller
- (void) codeaWillRestart:(ThreadedRuntimeViewController*)controller;

/// Called each frame update
/// - Parameters:
///   - controller: Runtime controller
///   - deltaTime: Time delta between this frame and the previous frame
- (void) codeaWillDrawFrame:(ThreadedRuntimeViewController*)controller withDelta:(CGFloat)deltaTime;

/// Called after initial setup
/// - Parameter controller: Runtime controller
- (void) codeaDidFinishSetup:(ThreadedRuntimeViewController*)controller;

/// Called when the addon is registered
/// - Parameter controller: Runtime controller
- (void) codeaDidRegisterAddon:(ThreadedRuntimeViewController*)controller;

/// Called when the runtime prints regular output
/// - Parameters:
///   - controller: Runtime controller
///   - text: Output printed
- (void) codea:(ThreadedRuntimeViewController*)controller didPrint:(NSString*)text;

/// Called when the runtime prints a warning
/// - Parameters:
///   - controller: Runtime controller
///   - text: Warning message
- (void) codea:(ThreadedRuntimeViewController*)controller didWarn:(NSString*)text;

/// Called when the runtime prints an error message
/// - Parameters:
///   - controller: Runtime controller
///   - error: Error message output
- (void) codea:(ThreadedRuntimeViewController*)controller didError:(NSString*)error;

@end

NS_ASSUME_NONNULL_END
