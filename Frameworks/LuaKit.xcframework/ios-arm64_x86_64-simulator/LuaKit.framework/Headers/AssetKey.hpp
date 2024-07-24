//
//  AssetKey.hpp
//  LuaKit
//
//  Created by Sim Saens on 12/2/2024.
//

#ifndef AssetKey_hpp
#define AssetKey_hpp

#ifdef __cplusplus

#include <string>
#include <functional>

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

struct AssetKey {
    
    using ReadSaveCoordinator = std::function<void(const std::string&)>;

    std::string _path;
    
    #ifdef __OBJC__
    NSURL* _Nullable _rootUrl;
    #else
    void* _rootUrl; // C++ compatibility
    #endif
    
    AssetKey() {}
    
    explicit AssetKey(const std::string& path): _path(path) {}
    
    #ifdef __OBJC__
    explicit AssetKey(const std::string& path, NSURL* _Nonnull rootUrl): _path(path), _rootUrl(rootUrl) {}
    #else
    explicit AssetKey(const std::string& path, void* rootUrl): _path(path), _rootUrl(rootUrl) {}
    #endif
    
    std::string name() const;
            
    const std::string& path() const {
        return _path;
    }

    #ifdef __OBJC__
    const NSURL* _Nullable rootUrl() const {
        return _rootUrl;
    }
    #else
    const void* rootUrl() const {
        return _rootUrl;
    }
    #endif
    
    void coordinateRead(ReadSaveCoordinator reader) const;
    
    void coordinateSave(ReadSaveCoordinator saver) const;

    std::string ext() const;
    
    std::string type() const;
    
    static AssetKey empty();
    
    bool isEmpty() const {
        return _path == "";
    }
};

inline bool operator==(const AssetKey& lhs, const AssetKey& rhs) {
    return lhs._path == rhs._path;
}

struct lua_State;

#ifdef __OBJC__
/// Gets an AssetKey on the stack at the given index. This must be used to retrieve asset keys
/// from Lua
/// - Parameters:
///   - L: The Lua state
///   - index: Stack index
AssetKey lua_assetkey(struct lua_State* _Nonnull L, int index);

/// Checks if item on the stack is an AssetKey
/// - Parameters:
///   - L: The Lua state
///   - index: Stack index 
bool lua_isassetkey(struct lua_State* _Nonnull L, int index);
#else
AssetKey lua_assetkey(struct lua_State* L, int index);
bool lua_isassetkey(struct lua_State* L, int index);
#endif

#endif /* __cplusplus */

#endif /* AssetKey_hpp */
