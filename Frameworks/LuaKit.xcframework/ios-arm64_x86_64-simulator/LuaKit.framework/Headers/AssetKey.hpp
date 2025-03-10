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
    mutable void* _rootUrl;
    mutable void* _bookmarkData;
    
    AssetKey(): _path(""), _rootUrl(nullptr), _bookmarkData(nullptr) {}
    ~AssetKey();
    
    explicit AssetKey(const std::string& path);
    explicit AssetKey(const std::string& path, void* rootUrl);
    explicit AssetKey(const std::string& path, bool withBookmarkData);
    explicit AssetKey(void* _Nonnull bookmarkData);
    AssetKey(AssetKey&& other) noexcept;
        
    #ifdef __OBJC__
    explicit AssetKey(const std::string& path, NSURL* _Nonnull rootUrl);
    explicit AssetKey(NSData* _Nonnull bookmarkData);
    #endif
    AssetKey(const AssetKey& other);
    
    AssetKey& operator=(const AssetKey& other);
    AssetKey& operator=(AssetKey&& other) noexcept;
    
    std::string name() const;
            
    const std::string& path() const {
        return _path;
    }

    bool startAccessingRootURL() const;
    void stopAccessingRootURL() const;
    
    void createOrRefreshBookmarkData() const;
    
    void resolveBookmarkUrl() const;
    
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

/// Pushes an AssetKey onto the Lua stack
/// - Parameters:
///  - L: The Lua state
///  - key: The AssetKey to push
void lua_pushassetkey(lua_State* _Nonnull L, const AssetKey& key);
#else
AssetKey lua_assetkey(struct lua_State* L, int index);
bool lua_isassetkey(struct lua_State* L, int index);
void lua_pushassetkey(lua_State* L, const AssetKey& key);
#endif

#endif /* __cplusplus */

#endif /* AssetKey_hpp */
