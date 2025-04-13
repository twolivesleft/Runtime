//
//  vec3.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 26/09/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

#ifndef Codify_vec3_h
#define Codify_vec3_h

#ifdef __cplusplus
extern "C" {
#endif

#import <LuaKit/lua.h>

#define CODEA_VEC3LIBNAME "vec3"

LUALIB_API int (luaopen_vec3) (lua_State *L);
lua_Number *getvec3(lua_State *L, int i);
lua_Number *checkvec3(lua_State *L, int i);
void pushvec3(lua_State *L, lua_Number x, lua_Number y, lua_Number z);

#ifdef __cplusplus
}
#endif

#endif
