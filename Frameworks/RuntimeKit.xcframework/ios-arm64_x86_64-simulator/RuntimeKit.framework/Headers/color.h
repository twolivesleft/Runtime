//
//  color.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 20/09/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

#ifndef Codify_color_h
#define Codify_color_h

#ifdef __cplusplus
extern "C" {
#endif

#import <LuaKit/lua.h>

#define CODEA_COLORLIBNAME "color"

typedef struct color_type_t
{
    lua_Number r,g,b,a;
} color_type;

LUALIB_API int (luaopen_color) (lua_State *L);
color_type *getcolor(lua_State *L, int i);
color_type *checkcolor(lua_State *L, int i);

//Creates the userdata and puts it on the stack, and returns the same userdata
color_type* pushcolor(lua_State *L, lua_Number r, lua_Number g, lua_Number b, lua_Number a);

#ifdef __cplusplus
}
#endif

#endif
