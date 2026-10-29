//
//  Mic.h
//  LuaKit
//
//  Created by Simeon Saint-Saens on 30/7/18.
//  Copyright © 2018 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef Lua_mic_h
#define Lua_mic_h

#ifdef __cplusplus
extern "C" {
#endif
    #import <LuaKit/lua.h>

    void luamodule_mic(lua_State *L);

    /// Stops the microphone if a project started it
    void luamodule_mic_stop(void);
    /// Releases only this Lua state's capture request; other projects keep recording.
    void luamodule_mic_stop_for_state(lua_State *L);

#ifdef __cplusplus
}
#endif

#endif
