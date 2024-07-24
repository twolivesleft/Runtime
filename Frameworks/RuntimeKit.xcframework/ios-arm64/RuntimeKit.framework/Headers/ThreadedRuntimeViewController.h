//
//  ThreadedRuntimeViewController.h
//  Runtime
//
//  Created by Dylan Sale on 28/01/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <RuntimeKit/CodeaLuaError.h>
#import <RuntimeKit/CodeaAddon.h>

@class EAGLView;
@class CodeaGame;
@class CodeaLuaState;
@class CodeaViewController;
@class Project;
@class CodeaScriptExecute;
@class ScreenCapture;
@class RenderManager;
@class PhysicsManager;
@class ShaderManager;
@class TextureCache;
@class KeyboardInputView;
@class AFHTTPRequestOperationManager;
@class LocationManager;

@class ThreadedRuntimeViewController;

@protocol ScriptValidateErrorDelegate;
@protocol CodeaLuaStateDelegate;
@protocol ScreenCaptureDelegate;

NS_ASSUME_NONNULL_BEGIN

@protocol ThreadedRuntimeViewControllerDelegate <NSObject>

@optional
    //Asynchronous
    - (void)runtimeViewController:(id)context willPause:(BOOL)pause;
    - (void)runtimeViewControllerWillRestart:(id)context;
    - (void)runtimeViewControllerDidRestart:(id)context;
    - (void)runtimeViewControllerUpdate:(id)context;
    - (void)runtimeViewControllerWillClose:(id)context;
    - (void)runtimeViewControllerDidFinishSetup:(id)context;

    //Synchronous
    - (void)runtimeViewControllerWillDraw:(id)context;
    - (void)runtimeViewControllerDidDraw:(id)context;
@end

@interface ThreadedRuntimeViewController : UIViewController

@property (nullable, weak, nonatomic) id<ThreadedRuntimeViewControllerDelegate> delegate;
@property (nonatomic, readonly) CodeaGame* game;
/**
 Warning, the lua and screen capture delegate methods occur on the lua thread. This is a leaky abstraction, but c'est la vie.
 
 (•_•)
 ( •_•)>⌐■-■
 (⌐■_■)
 
 Deal With It.
*/
@property (nullable, weak, nonatomic) id<CodeaLuaStateDelegate> luaDelegate;
@property (nullable, weak, nonatomic) id<ScreenCaptureDelegate> screenCaptureDelegate;

@property (nullable, strong, nonatomic) Project *project;

- (nonnull id) initWithAddons:(NSArray<id<CodeaAddon>>*)addons;

- (void) setErrorDelegate:(nullable id<ScriptValidateErrorDelegate>)errorDelegate;

- (void) evaluateString:(NSString*) string;

- (void) loadString:(NSString*) string completion:(nullable void(^)(LuaError))completion;

- (void) loadString:(NSString*)string bufferName:(NSString*)name completion:(nullable void(^)(LuaError))completion;

- (void) hasScriptGlobal:(NSString *)name completion:(void(^)(BOOL))completion;

- (void) validateProject:(Project*)project completionBlock:(void(^)(BOOL))block; //Runs completion block on the main thread, validates the project on the lua thread

- (void) registerAddons:(NSArray<id<CodeaAddon>>*)addons;

#pragma mark - Unsafe stuff that you should only touch if you know what you are doing.

#pragma mark - Threading

//This leaks the luaState abstraction by passing it into a block.
//It should be removed but its the best solution for some legacy stuff for now.
//It will run the block on the lua thread.
#pragma warning This causes an unsafe abstraction leak.
- (void) unsafeRunLuaBlock:(void(^)(CodeaLuaState* state))block;

- (void) runBlock:(dispatch_block_t)block;
- (void) runGLBlock:(dispatch_block_t)block;

#pragma mark - Animation

- (void)startAnimation;
- (void)stopAnimationAndForceCancelFrame:(BOOL)forceFrame;

#pragma mark - EAGL

- (EAGLView*) glView;

#pragma mark - Frame timing

- (NSTimeInterval) currentDelta;

#pragma mark - Screen recording

- (void) stopRecording:(dispatch_block_t)completionBlock;
- (void) stopRecordingAndDiscard:(nullable void(^)(BOOL stopped))completionBlock;
- (void) discardMovie;
- (void) saveMovieToCameraRoll;
- (void) toggleRecording;

- (void) screenshot:(void(^)(UIImage* capture))capture;
- (void) screenshotAtScaleFactor:(CGFloat)scaleFactor completion:(void(^)(UIImage* capture))capture;

@property (nonatomic, assign) BOOL paused;

- (void) start:(void(^)())completion;
- (void) restart;
- (void) close:(dispatch_block_t)completion;
- (void) callWillClose:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
