//
//  LuaRefContainer.h
//  RuntimeKit
//
//  Created by Simeon Saint-Saens on 4/10/18.
//  Copyright © 2018 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
namespace LuaIntf {
    class LuaRef;
}
#endif

struct lua_State;

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

extern NSString * const LuaRefContainerContextKey;

#ifdef __cplusplus
}
#endif

/// Objects implementing `LuaRefContext` should run the provided
/// closure on their Lua thread, or guarantee isolation when running it
@protocol LuaRefContext<NSObject>
- (void) runInLuaContext:(dispatch_block_t)block;
@end

@interface LuaRefContainer : NSObject

@property (nonatomic, weak) id<LuaRefContext> context;

#ifdef __cplusplus
@property (nonatomic, readonly) LuaIntf::LuaRef reference;

/// Create a container for LuaRef that deallocates in the Lua context, as defined
/// by any object conforming to `LuaRefContext` set in the `LUA_REGISTRYINDEX`
/// - Parameters:
///   - ref: LuaRef to wrap
- (nonnull instancetype) initWithReference:(LuaIntf::LuaRef)ref;
#endif

- (void) unreference;

/// Install a given `LuaRefContext` into the supplied `lua_State`
/// - Parameters:
///   - context: The context to configure as light user data
///   - L: The Lua state on which to configure it
+ (void) installLuaRefContext:(id<LuaRefContext>)context luaState:(struct lua_State*)L;

@end

NS_ASSUME_NONNULL_END
