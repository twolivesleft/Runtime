//
//  File.h
//  LuaKit
//
//  Created by Claude Code on 27/8/2025.
//

#ifndef Lua_File_h
#define Lua_File_h

#ifdef __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>
#import <LuaKit/lua.h>
#import <LuaKit/lauxlib.h>

void luamodule_file(lua_State * _Nonnull L);

#ifdef __cplusplus
}
#endif

#endif