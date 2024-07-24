//
//  vec4.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 26/09/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

#ifndef Codea_vec4_h
#define Codea_vec4_h

#ifdef __cplusplus
extern "C" {
#endif

#import <LuaKit/lua.h>

#define CODEA_VEC4LIBNAME "vec4"

LUALIB_API int (luaopen_vec4) (lua_State *L);
lua_Number *getvec4(lua_State *L, int i);
lua_Number *checkvec4(lua_State *L, int i);
void pushvec4(lua_State *L, lua_Number x, lua_Number y, lua_Number z, lua_Number w);

#ifdef __cplusplus
}
#endif

#endif
