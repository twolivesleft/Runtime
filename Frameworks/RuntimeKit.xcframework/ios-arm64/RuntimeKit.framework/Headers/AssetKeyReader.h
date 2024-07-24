//
//  AssetKeyReader.h
//  RuntimeKit
//
//  Created by Sim Saens on 16/2/2024.
//  Copyright © 2024 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef AssetKeyReader_h
#define AssetKeyReader_h

/*
 
 This file declares a series of functions that can be used to safely read
 asset keys and legacy "String:Keys" from a Lua state. It is useful when
 needing to handle both these types of resource identifiers
 
 For modern code wanting to handle just asset keys, please use the libraries
 in LuaKit and AssetKit directly
 
 */

#ifdef __cplusplus
extern "C" {
#endif

struct lua_State;

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, AssetKeyStackOptions) {
    AssetKeyStackOptionsMustExist = 1 << 1,
    AssetKeyStackOptionsAllowLibraries = 1 << 2,
    AssetKeyStackOptionsShowWarning = 1 << 3,
};

typedef void (^AssetKeyReaderBlock)(NSURL* path);

/// Ensures that the asset on the Lua stack at the given index is security scoped within the call to the `reader` block. Note
/// this method does not perform file coordination, and you must perform file coordination yourself when using this function
/// - Parameters:
///   - L: Lua state
///   - idx: Stack index
///   - options: Asset access options
///   - reader: Reader block in which data can be read using file coordination
void securityScopeAssetOnStackAtIndex(struct lua_State *L, int idx, AssetKeyStackOptions options, AssetKeyReaderBlock reader);

/// Fully coordinates reading of an asset on the Lua stack at the given index. This means that both security scoping and file
/// coordination are handled, and you are free to load data within the supplied `AssetKeyReaderBlock`
/// - Parameters:
///   - L: Lua state
///   - idx: Stack index
///   - options: Asset access options
///   - reader: Reader block in which data can be read
void readAssetOnStackAtIndex(struct lua_State *L, int idx, AssetKeyStackOptions options, AssetKeyReaderBlock reader);

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
}
#endif

#endif /* AssetKeyReader_h */
