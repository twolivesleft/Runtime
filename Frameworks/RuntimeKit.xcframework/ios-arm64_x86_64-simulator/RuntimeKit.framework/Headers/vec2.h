//
//  vec2.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 26/09/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

#ifndef Codify_vec2_h
#define Codify_vec2_h

#ifdef __cplusplus
extern "C" {
#endif

#import <LuaKit/lua.h>

#define CODEA_VEC2LIBNAME "vec2"

LUALIB_API int (luaopen_vec2) (lua_State *L);
lua_Number *getvec2(lua_State *L, int i);
lua_Number *checkvec2(lua_State *L, int i);
void pushvec2(lua_State *L, lua_Number x, lua_Number y);

#ifdef __cplusplus
}
#endif

#endif
