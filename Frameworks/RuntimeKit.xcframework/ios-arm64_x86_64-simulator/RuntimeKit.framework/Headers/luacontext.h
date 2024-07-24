//
//  lua_context.h
//  Runtime
//
//  Created by John Millard on 9/10/12.
//  Copyright (c) 2012 Two Lives Left. All rights reserved.
//

#ifndef luacontext_h
#define luacontext_h

#ifdef __cplusplus
extern "C" {
#endif

#import <LuaKit/lua.h>

LUA_API void* lua_getcontext (lua_State *L);
LUA_API void lua_setcontext (lua_State *L, void* context);

#ifdef __cplusplus
}
#endif

#endif
