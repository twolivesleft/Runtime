//
//  CodeaLuaState.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 17/05/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#ifdef __cplusplus
extern "C" {
#endif

#include <RuntimeKit/touch.h>
    
#ifdef __cplusplus
}
#endif

#include <RuntimeKit/gesture.h>
#import <RuntimeKit/CodeaLuaError.h>

extern NSString * const CodeaLuaStateWillCloseNotification;

@class CodeaLuaState;

@protocol CodeaLuaStateDelegate <NSObject>

- (void) luaStateCreated:(CodeaLuaState*)state isValidating:(BOOL)validating;

- (void) luaState:(CodeaLuaState*)state printedText:(NSString*)text;
- (void) luaState:(CodeaLuaState*)state tracedText:(NSString*)text;
- (void) luaState:(CodeaLuaState*)state warningText:(NSString*)text;
- (void) luaState:(CodeaLuaState*)state errorOccured:(NSString*)error;

- (void) clearOutputForCodeaLuaState:(CodeaLuaState*)state;

- (void) removeAllParametersForCodeaLuaState:(CodeaLuaState*)state;

- (void) luaState:(CodeaLuaState *)state registerWatch:(NSString*)expression;

- (void) luaState:(CodeaLuaState*)state registerFloatParameter:(NSString*)text initialValue:(CGFloat)value withMin:(CGFloat)min andMax:(CGFloat)max callback:(int)callback;

- (void) luaState:(CodeaLuaState*)state registerIntegerParameter:(NSString*)text initialValue:(NSInteger)value withMin:(NSInteger)min andMax:(NSInteger)max callback:(int)callback;

- (void) luaState:(CodeaLuaState *)state registerColorParameter:(NSString*)name initialRed:(CGFloat)red initialGreen:(CGFloat)green initialBlue:(CGFloat)blue initialAlpha:(CGFloat)alpha callback:(int)callback;

- (void) luaState:(CodeaLuaState *)state registerBoolParameter:(NSString*)name initialValue:(BOOL)initial callback:(int)callback;

- (void) luaState:(CodeaLuaState *)state registerTextParameter:(NSString*)name initialValue:(NSString*)initial callback:(int)callback;

- (void) luaState:(CodeaLuaState *)state registerActionParameter:(NSString*)name callback:(int)callback;

- (void) luaStateUpdatedParameters:(CodeaLuaState *)state;

- (void) luaStateWillClose:(CodeaLuaState*)state;

@end

struct lua_State;

@class RuntimeViewController;

@interface CodeaLuaState : NSObject 
{
    struct lua_State *L;
    __weak id codeaContext;
    BOOL usingFakeLibs;
}

@property (nonatomic,weak) id<CodeaLuaStateDelegate> delegate;
@property (nonatomic,readonly) struct lua_State* L;
@property (nonatomic,readonly) BOOL available;
@property (nonatomic,readonly) BOOL isUsingFakeLibs;
@property (nonatomic,assign) BOOL shouldForceTerminate;

@property (class) BOOL isRunningInCodea;

- (id) initWithCodeaContext:(id)codeaContext;
- (void) create;
- (void) createWithFakeLibs;

- (void) disableViewerStateCommands;

- (void) close;

- (void) hookClosingLineCountFunction;

- (void) evaluateString:(NSString*)string;
- (NSString*) evaluateWatchExpression:(NSString*)string;
- (LuaError) loadString:(NSString*)string;
- (LuaError) loadString:(NSString*)string bufferName:(NSString*)name;

- (NSString*) stackArgumentsToString;

- (BOOL) hasGlobal:(NSString*)name;

- (void*) createGlobalUserData:(size_t)size withTypeName:(NSString*)type andName:(NSString*)name;
- (lua_Number*) createGlobalVec3WithName:(NSString*)name;

- (void) setGlobalNumber:(lua_Number)number withName:(NSString*)name;
- (void) setGlobalBoolean:(BOOL)value withName:(NSString*)name;
- (void) setGlobalColorRed:(int)red green:(int)green blue:(int)blue alpha:(int)alpha withName:(NSString*)name;
- (void) setGlobalInteger:(int)number withName:(NSString*)name;
- (void) setGlobalString:(NSString*)string withName:(NSString*)name;

- (void*) globalUserData:(NSString*)name;
- (lua_Number) globalNumber:(NSString*)name;
- (lua_Integer) globalInteger:(NSString*)name;
- (BOOL) globalBoolean:(NSString*)name;
- (NSString*) globalString:(NSString*)name;

- (void) pcallAndReportErrors:(int)argCount;
- (void) printWarning:(NSString*)warning;
- (void) printTrace:(NSString*)trace;
- (void) printStackTrace;

- (BOOL) callSimpleFunction:(NSString*)funcName;
- (BOOL) callTouchFunction:(touch_data*)touches count:(NSUInteger)count;
- (BOOL) callKeyboardFunction:(NSString*)newText;
- (BOOL) callSizeChangedFunction:(CGSize)newSize;
- (void) callTweenUpdate;

#ifdef __cplusplus
- (BOOL) callGestureFunctionNamed:(NSString*)name gesture:(Gesture)gesture;
#endif

- (BOOL) pushFunction:(NSString*)funcName;
- (void) callFunctionWithArgCount:(int)argCount;

- (void) logStackSize:(NSString *)info;

@end
