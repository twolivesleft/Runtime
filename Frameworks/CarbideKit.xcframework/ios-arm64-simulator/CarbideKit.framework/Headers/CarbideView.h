//
//  CarbideView.h
//  Carbide
//
//  Created by John Millard on 2/3/19.
//  Copyright © 2019 John Millard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

#import "LuaKit/AirCode.h"

NS_ASSUME_NONNULL_BEGIN

struct lua_State;

@class AFHTTPRequestOperationManager;
@class CarbideProxyView;
@class CarbideView;

typedef enum {
    OutputTypeWarning,
    OutputTypeError,
    OutputTypeMessage
} OutputType;

typedef enum : NSUInteger {
    DisplayModeStandard,
    DisplayModeOverlay,
    DisplayModeFullscreen,
    DisplayModeFullscreenNoButtons
} DisplayMode;

@interface CarbideHost : UIView
{
}

@property (readonly) id<MTLDevice> device;
+ (instancetype) sharedInstance;
+ (dispatch_queue_t)displayQueue;

/// Whether the caller is running on any runtime-owned render queue.
+ (BOOL)isOnDisplayQueue;
@end

@protocol CarbideViewDelegate

- (void) carbideViewDidInitialize:(CarbideView*)view;
- (void) carbide:(CarbideView*)view didPause:(BOOL)pause;
- (void) carbide:(CarbideView*)view didChangeSize:(CGSize)size;

@end

@interface RuntimeStringLoader: NSObject
- (void)loadLuaString:(NSString*)string chunkName:(NSString*)chunkName completion:(void(^)(BOOL, NSError*))completion;
@end

@interface CarbideView : UIView

/// Resolves asset libraries inside the app bundle instead of Codea's documents, as an exported app does.
@property (class) BOOL isStandalone;
@property (readonly) dispatch_queue_t queue;
@property (atomic, strong, readonly) NSRunLoop* runLoop;
@property (nonatomic, readonly) NSURL* workingURL;
@property (strong, nonatomic) NSString* workingPath;
@property (nonatomic, strong, nullable) void (^outputBlock)(OutputType, NSString* message);
@property (nonatomic, strong, nullable) void (^outputClearBlock)();
@property (nonatomic, strong, nullable) void (^updateInspectorModelBlock)(NSString* json);
@property (nonatomic, strong) id<LuaDebugMessageInterface> debugMessageInterface;
@property (nonatomic, assign) BOOL drawOnRequest;
@property (nonatomic, assign) NSInteger preferredFPS;
@property (nonatomic, assign) BOOL displayStats;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, readonly) UIEdgeInsets safeArea;
@property (nonatomic, readonly) UIUserInterfaceSizeClass horizontalSizeClass;
@property (nonatomic, readonly) UIUserInterfaceSizeClass verticalSizeClass;
@property (nonatomic, readonly) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic, readonly) BOOL closing;
/// True once this runtime has submitted its first frame; cleared on reset.
@property (atomic, readonly) BOOL hasRenderedFrame;
@property (nonatomic, readonly) struct lua_State* luaState;
@property (nonatomic, weak) id<CarbideViewDelegate> delegate;
@property (strong, nullable) RuntimeStringLoader *stringLoader;

- (instancetype)initWithURL:(nonnull NSURL*)url;
- (instancetype)init NS_UNAVAILABLE;

- (void)runBlock:(dispatch_block_t)block;

- (void)addPackagePath:(NSString*)path;

- (BOOL)require:(NSString*)package error:(NSError **)error;
- (BOOL)loadFile:(NSString*)path error:(NSError **)error;
- (BOOL)loadLuaString:(NSString*)string error:(NSError **)error;
- (BOOL)loadLuaString:(NSString*)string chunkName:(NSString*)chunkName error:(NSError **)error;
- (void)loadLuaString:(NSString*)string chunkName:(NSString*)chunkName completion:(void(^)(NSError* _Nullable))completion;
- (void)loadLuaStrings:(NSArray<NSString*>*)strings chunkNames:(NSArray<NSString*>*)chunkNames completion:(void(^)(NSError* _Nullable))completion;

- (void)logMessage:(NSString *)message;
- (void)logError:(NSString *)message;
- (void)logWarning:(NSString *)message;

- (void)play;
- (void)stop;
- (void)reset:(dispatch_block_t)completion;
- (void)shutdown:(dispatch_block_t)completion;
- (void)callLuaShutdown:(dispatch_block_t)completion;

- (void)pauseAudio;
- (void)resumeAudio;

- (void)updateInspectorModel:(NSString*)json;

- (nullable CarbideProxyView*)proxyWithhandle:(NSUInteger)handle;

@end

NS_ASSUME_NONNULL_END
