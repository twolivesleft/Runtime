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

#define LUA_OBJCLIBNAME   "objc"
    
LUALIB_API int (luaopen_objc) (lua_State *L);

@class RenderMutex;

#pragma mark - Lua State Configuration
@interface LuaStateConfiguration: NSObject

@property (atomic, retain) RenderMutex* renderMutex;
@property (atomic, retain) NSMutableSet* activeClassNames;
@property (atomic, retain) NSMutableArray* waitingSemaphores;
@property (atomic, retain) dispatch_queue_t backgroundQueue;

@property (copy) void (^warningHandler)(NSString*);
@property (copy) void (^errorHandler)(NSString*);

@property (copy) UIViewController* (^getViewer)(void);

@property (copy) BOOL (^isUIColor)(lua_State* L, int n);
@property (copy) BOOL (^isUIImage)(lua_State* L, int n);
@property (copy) BOOL (^isCGPoint)(lua_State* L, int n);

@property (copy) UIColor* (^getUIColor)(lua_State* L, int n);
@property (copy) UIImage* (^getUIImage)(lua_State* L, int n);
@property (copy) NSValue* (^getCGPoint)(lua_State* L, int n);

@property (copy) void (^pushUIColor)(lua_State* L, UIColor* color);
@property (copy) void (^pushUIImage)(lua_State* L, UIImage* image);

@end

#pragma mark - Lua State Configurations
@interface LuaStateConfigurations: NSObject

@property (atomic, retain) NSMutableDictionary* configurations;
@property (atomic, retain) NSMutableSet* activeClassNames;
@property (atomic, strong) dispatch_queue_t isolationQueue;

+ (LuaStateConfigurations *) shared;

- (void) setConfiguration:(LuaStateConfiguration*)configuration forState:(lua_State*)L;
- (void) removeState:(lua_State*)L;
- (BOOL) containsState:(lua_State*)L withConfiguration:(LuaStateConfiguration*)configuration;
- (LuaStateConfiguration*) configurationForState:(lua_State*)L;

@end

#ifdef __cplusplus
}
#endif

#pragma mark - Lua Registerd Functions
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
