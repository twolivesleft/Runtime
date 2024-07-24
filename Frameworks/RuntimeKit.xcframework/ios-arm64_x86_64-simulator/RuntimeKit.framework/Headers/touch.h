//
//  touch.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 25/09/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

#ifndef Codify_touch_h
#define Codify_touch_h

#ifdef __cplusplus
extern "C" {
#endif

#import <LuaKit/lua.h>

#define CODEA_TOUCHLIBNAME "touch"

typedef enum interaction_state
{
    INTERACTION_STATE_BEGAN=0,
    INTERACTION_STATE_CHANGED,
    INTERACTION_STATE_ENDED,
    INTERACTION_STATE_INACTIVE,    
    INTERACTION_STATE_STATIONARY,

} interaction_state;

typedef enum touch_type
{
    TOUCH_TYPE_DIRECT=0,
    TOUCH_TYPE_INDIRECT,
    TOUCH_TYPE_PENCIL,
    TOUCH_TYPE_POINTER,
} touch_type;

typedef struct touch_data
{
    ptrdiff_t ID;
    
    lua_Number x;
    lua_Number y;
    lua_Number prevX;
    lua_Number prevY;
    lua_Number deltaX;
    lua_Number deltaY;
    lua_Number radius;
    lua_Number radiusTolerance;
    
    //Apple Pencil & 3D Touch support
    lua_Number force;
    lua_Number preciseX;
    lua_Number preciseY;
    lua_Number previousPreciseX;
    lua_Number previousPreciseY;
    lua_Number maximumPossibleForce;
    lua_Number altitudeAngle;
    lua_Number azimuthAngle;
    lua_Number azimuthUnitVectorX;
    lua_Number azimuthUnitVectorY;
    
    //Timestamp
    double timestamp;
    
    unsigned int type;
    unsigned int state;
    unsigned int tapCount;
} touch_data;

LUALIB_API int (luaopen_touch) (lua_State *L);

void setupEmptyTouch(touch_data* t);
touch_data *setupNewTouch(lua_State *L);

#ifdef __cplusplus
}
#endif

#endif
