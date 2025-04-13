//
//  CodeaGame.h
//  Runtime
//
//  Created by Dylan Sale on 28/01/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import "RendererPlatformSupport.h"

#if TARGET_OS_SUPPORTS_GL
#import <OpenGLES/EAGL.h>
#endif

#import <RuntimeKit/Game.h>
#import <RuntimeKit/RendererDelegate.h>
#import <RuntimeKit/CodeaLuaError.h>

#ifdef __cplusplus
extern "C" {
#endif
    
#include <RuntimeKit/touch.h>
    
#ifdef __cplusplus
}
#endif

#include <RuntimeKit/gesture.h>

@class Project;
@class CodeaScriptExecute;
@class Renderer;
@class ScreenCapture;
@class RenderManager;
@class PhysicsManager;
@class ShaderManager;
@class TextureCache;
@class KeyboardInputView;
@class AFHTTPRequestOperationManager;
@class LocationManager;

#if TARGET_OS_SUPPORTS_GL
@class EAGLView;
#endif

@class CodeaLuaState;
@class SpeechSynthesis;

@protocol ThreadedRuntimeViewControllerDelegate;
@protocol ScriptValidateErrorDelegate;
@protocol Game;

#define CodeaContext(L) ((__bridge CodeaGame*)lua_getcontext((L)))
#define CodeaContextNoARC(L) ((CodeaGame*)lua_getcontext((L)))

@interface CodeaGame : NSObject<Game, RendererDelegate>

#if TARGET_OS_SUPPORTS_GL
@property (nonatomic, strong)   EAGLContext *context;
@property (nonatomic, readonly) EAGLRenderingAPI GLAPILevel;
@property (nonatomic, readonly) EAGLView *glView;
#endif

@property (nonatomic, readonly) RenderManager *renderManager;
@property (nonatomic, readonly) CodeaLuaState *luaState;
@property (nonatomic, readonly) CodeaScriptExecute *scriptExecute;
@property (nonatomic, readonly) ScreenCapture *screenCapture;
@property (nonatomic, readonly) ShaderManager *shaderManager;
@property (nonatomic, readonly) PhysicsManager *physicsManager;
@property (nonatomic, readonly) TextureCache *textureCache;
@property (nonatomic, readonly) AFHTTPRequestOperationManager *httpClient;
@property (nonatomic, readonly) LocationManager *locationManager;
@property (nonatomic, readonly) SpeechSynthesis *speechManager;
@property (nonatomic, readonly) Renderer* renderer;
@property (nonatomic, assign) BOOL showWarnings;

@property (nonatomic, strong) Project *project;
@property (nonatomic, weak) id<ThreadedRuntimeViewControllerDelegate> delegate;

@property (nonatomic, readonly) NSString *currentPrefix;
@property (nonatomic, readonly) NSMutableDictionary *currentLocalStore;
@property (nonatomic, readonly) NSMutableDictionary *currentGlobalStore;
@property (nonatomic, readonly) NSMutableDictionary *currentProjectStore;
@property (nonatomic, readonly) NSMutableDictionary *currentProjectInfoStore;
@property (nonatomic, readonly) NSString *currentProjectDataPath;

@property (nonatomic, readonly) NSTimeInterval currentDelta;

@property (nonatomic, readwrite) BOOL showKeyboard;
@property (nonatomic, readonly) NSString* currentKeyboardText;

@property (nonatomic, readonly) UIViewController* viewController;
@property (nonatomic, readonly) CGRect bounds;

@property (nonatomic, readonly) CGFloat contentScaleFactor;

@property (nonatomic, weak) id<ScriptValidateErrorDelegate> errorDelegate;

// Layout Properties

@property (atomic, assign) UIEdgeInsets safeAreaInsets;
@property (atomic, assign) UIUserInterfaceSizeClass horizontalSizeClass;
@property (atomic, assign) UIUserInterfaceSizeClass verticalSizeClass;

// Viewer properties

@property (atomic, assign) NSInteger preferredFPS;

- (id) initWithRenderer:(Renderer*) renderer andKeyboardView:(KeyboardInputView*)keyboardView inViewController:(UIViewController*)viewController;

- (void) setupDataStore;
- (void) cleanupDataStore;

- (void) saveProjectStore;
- (void) clearProjectStore;
- (void) saveLocalStore;
- (void) clearLocalStore;

- (void) saveProjectInfo;

#if TARGET_OS_TV
- (void) setupRenderGlobalsWithBounds:(CGRect)bounds;
#else
- (void) setupRenderGlobalsWithOrientation:(UIInterfaceOrientation)orientation andBounds:(CGRect)bounds;
#endif
- (void) setupRenderGlobals;
- (void) setupPhysicsGlobals;
- (void) setupAccelerometerValues;

- (void) updateScriptScreenDimensions:(CGRect)bounds;
#if !TARGET_OS_TV
- (void) updateScriptOrientation:(UIInterfaceOrientation)interfaceOrientation;
#endif
- (void) start:(void(^)())completion;
- (void) close:(void(^)())completion;
- (void) restart;
- (void) setupGL;

- (LuaError) loadScript:(NSString *)script;

- (BOOL) validateProject:(Project*)project;

- (void) runBlock:(dispatch_block_t)block;
- (void) runBlockWithEAGLContext:(dispatch_block_t)block;

#ifdef __cplusplus
- (void) pinch:(Gesture)gesture;
- (void) hover:(Gesture)gesture;
- (void) scroll:(Gesture)gesture;
#endif

- (void) touchesBegan:(touch_data*)touches count:(NSUInteger)count;
- (void) touchesCancelled:(touch_data*)touches count:(NSUInteger)count;
- (void) touchesMoved:(touch_data*)touches count:(NSUInteger)count;
- (void) touchesEnded:(touch_data*)touches count:(NSUInteger)count;

- (void) registerScreenshotCapture:(void(^)(UIImage* capture))capture onQueue:(dispatch_queue_t)queue;
- (void) registerScreenshotCapture:(void(^)(UIImage* capture))capture atScaleFactor:(CGFloat)scale onQueue:(dispatch_queue_t)queue;

@end
