//
//  Assets.h
//  LuaKit
//
//  Created by Simeon Saint-Saens on 21/1/20.
//  Copyright © 2020 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetKit/AssetKit.h>

#ifdef __cplusplus
#include "AssetKey.hpp"
#endif

#ifndef Codea_assets_h
#define Codea_assets_h

@class AssetLibrary;

#ifdef __cplusplus
extern "C" {
#endif //__cplusplus
    #import <LuaKit/lua.h>
    
    NS_ASSUME_NONNULL_BEGIN

    void luamodule_assets(lua_State *L, NSString* projectPath, BOOL isRunningInCodea);
    
    //MARK: Asset paths

    NSArray<NSDictionary<NSString*, NSObject*> *> *assetLocations(NSString *projectPath, BOOL isHosted);

    NSString* _Nullable assetCodePath(NSString *path, NSString* _Nullable projectPath);

    NS_ASSUME_NONNULL_END
#ifdef __cplusplus
}
#endif //__cplusplus

#ifdef __cplusplus

/// Gets an AssetLibrary on the stack at the given index. An AssetLibrary represents a folder or collection
/// of assets, and is not the same as an AssetKey (which represents a single file)
/// - Parameters:
///   - L: The Lua state
///   - index: Stack index
AssetLibrary* _Nullable assetLibrary(lua_State* _Nonnull L, int index);

#endif //__cplusplus

#endif // __Codea_assets_h
