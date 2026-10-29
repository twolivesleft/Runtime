//
//  LuaBridgedFunctions.h
//  Pods
//
//  Created by David Holtkamp on 4/1/15.
//
//  -- Modified for Codea by Jean-François Pérusse 2021-12
//

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>

#import <LuaKit/lua.h>
#import <LuaKit/lauxlib.h>

#import <UIKit/UIKit.h>

#import "AirCode.h"

#define LUA_OBJCLIBNAME   "objc"
    
LUALIB_API int (luaopen_objc) (lua_State *L);

@class RenderMutex;
@class LuaHingeInput;

typedef struct {
    UIEdgeInsets safeArea;
    UIUserInterfaceSizeClass horizontalSizeClass;
    UIUserInterfaceSizeClass verticalSizeClass;
    NSInteger interfaceOrientation; // UIInterfaceOrientation; 0 when unknown or unavailable
} LuaLayoutTraits;

#pragma mark - Lua State Configuration
@interface LuaStateConfiguration: NSObject

@property (atomic, retain) RenderMutex* renderMutex;
@property (atomic, retain) NSMutableSet* activeClassNames;
@property (atomic, retain) NSMutableArray* waitingSemaphores;
@property (atomic, retain) dispatch_queue_t backgroundQueue;

@property (nonatomic, weak) id<LuaDebugMessageInterface> debugMessageInterface;

@property (copy) void (^warningHandler)(NSString*);
@property (copy) void (^errorHandler)(NSString*);

@property (copy) UIViewController* (^getViewer)(void);

/// Called on the Lua thread, so it must return values captured on the main thread rather than query UIKit.
@property (copy) LuaLayoutTraits (^getLayoutTraits)(void);

@property (nonatomic, strong) LuaHingeInput *hingeInput;

@property (copy) BOOL (^isUIColor)(lua_State* L, int n);
@property (copy) BOOL (^isUIImage)(lua_State* L, int n);
@property (copy) BOOL (^isCGPoint)(lua_State* L, int n);

@property (copy) UIColor* (^getUIColor)(lua_State* L, int n);
@property (copy) UIImage* (^getUIImage)(lua_State* L, int n);
@property (copy) NSValue* (^getCGPoint)(lua_State* L, int n);

@property (copy) void (^pushUIColor)(lua_State* L, UIColor* color);
@property (copy) void (^pushUIImage)(lua_State* L, UIImage* image);

/// When NO, `to_lua` stops converting bridged UIImage/UIColor values into their
/// Codea equivalents and hands back the wrapped Objective-C object instead, so
/// Lua can configure it (tintColor, rendering mode) before converting. Defaults
/// to YES. Exposed to Lua as `objc.automaticBridging`.
@property (atomic, assign) BOOL automaticBridging;

/// Releases every Lua thread parked in `objc.semaphore:wait()` and latches the
/// state so a wait started afterwards returns immediately instead of parking.
///
/// Lua runs on the runtime's own serial queue, so a project blocked in a wait —
/// `pick` with its picker still on screen, `require` waiting on a file
/// coordinator — occupies that queue and any teardown work queued behind it
/// never runs. Cancelling has to happen before that work is queued, and it has
/// to latch: the freed Lua carries on running the rest of `setup`, which is free
/// to start another wait that a one-shot sweep would miss.
- (void) cancelWaits;

@end

#pragma mark - Lua State Configurations
@interface LuaStateConfigurations: NSObject

@property (atomic, retain) NSMutableDictionary* configurations;
@property (atomic, retain) NSMutableSet* activeClassNames;
@property (atomic, strong) dispatch_queue_t isolationQueue;

+ (LuaStateConfigurations *) shared;

- (void) setConfiguration:(LuaStateConfiguration*)configuration forState:(lua_State*)L;
- (void) cancelWaitsForState:(lua_State*)L;
- (void) removeState:(lua_State*)L;
- (BOOL) containsState:(lua_State*)L withConfiguration:(LuaStateConfiguration*)configuration;
- (LuaStateConfiguration*) configurationForState:(lua_State*)L;

@end

#ifdef __cplusplus
}
#endif

#pragma mark - Lua Registerd Functions
/// A lua_State private to the calling thread, sharing _G and the collector with
/// every other. Requires the render mutex; without it the shared state is
/// returned, which is what project setup in CodeaScriptExecute gets, as it runs
/// before any other thread has a frame on the state.
lua_State *luakit_state_for_current_thread(lua_State *L);

/// Creates the state per-thread states are allocated from. Call while the Lua
/// state is still single-threaded.
void luakit_install_state_factory(lua_State *L);

int luafunc_call(lua_State *L);
int luafunc_getclass(lua_State *L);
int luafunc_hasmethod(lua_State *L);
int luafunc_hasvariable(lua_State *L);
int luafunc_hasproperty(lua_State *L);
int luafunc_getproperty(lua_State *L);
int luafunc_classof(lua_State *L);
int luafunc_nslog(lua_State *L);
int luafunc_release(lua_State *L);
int luafunc_warning(lua_State *L);
int luafunc_createstruct(lua_State *L);
int luafunc_inspectclass(lua_State *L);
