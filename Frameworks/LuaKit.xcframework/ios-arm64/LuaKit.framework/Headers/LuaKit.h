//
//  LuaKit.h
//  LuaKit
//
//  Created by Sim Saens on 16/9/2022.
//

#import <Foundation/Foundation.h>

//! Project version number for ToolKit.
FOUNDATION_EXPORT double LuaKitVersionNumber;

//! Project version string for ToolKit.
FOUNDATION_EXPORT const unsigned char LuaKitVersionString[];

#import <LuaKit/LuaBridgedFunctions.h>
#import <LuaKit/LuaLibraries.h>
#import <LuaKit/AirCode.h>
#import <LuaKit/Assets.h>
#import <LuaKit/AssetKey.hpp>
#import <LuaKit/LuaRefContainer.h>
#import <LuaKit/NSBundle+Lua.h>

#ifdef __cplusplus
#import <LuaKit/lua.hpp>
#else
#import <LuaKit/lua.h>
#import <LuaKit/lualib.h>
#import <LuaKit/lauxlib.h>
#endif
