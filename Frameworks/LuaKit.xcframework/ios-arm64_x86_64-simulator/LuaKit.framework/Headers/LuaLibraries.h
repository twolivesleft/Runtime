//
//  LuaLibraries.hpp
//  Lua
//
//  Created by Sim Saens on 15/9/2022.
//

#ifndef LuaLibraries_h
#define LuaLibraries_h

#ifdef __cplusplus
extern "C"
{
#endif
    #import <LuaKit/lua.h>
    #import <LuaKit/lauxlib.h>
    #import <LuaKit/lualib.h>
    #import <LuaKit/luasocket.h>

    int luaopen_lpeg(lua_State *L);
    int luaopen_lfs(lua_State * L);
#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
    #define SOL_STD_VARIANT 1
    //#define SOL_USING_CXX_LUA 1
    #define SOL_ALL_SAFETIES_ON 1
    #define SOL_NO_CHECK_NUMBER_PRECISION 1
    //#define SOL_EXCEPTIONS_ALWAYS_UNSAFE 1
    #include <sol/sol.hpp>
#endif

#endif /* LuaLibraries_h */
