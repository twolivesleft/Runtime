//
//  layout.h
//  RuntimeKit
//
//  Created by Simeon Saint-Saens on 02/1/19.
//  Copyright © 2019 Two Lives Left. All rights reserved.
//

#ifndef Lua_layout_h
#define Lua_layout_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <stdbool.h>

/// Captures UIKit input on the main thread; Lua consumes it on its own queue.
@interface LuaHingeInput : NSObject
- (instancetype)initWithViewProvider:(UIView *(^)(void))provider;
@end


#ifdef __cplusplus
extern "C" {
#endif
    #import <LuaKit/lua.h>
    
    void luamodule_layout(lua_State *L);
    /// Publishes the latest angle and leaves hingeChanged plus two arguments
    /// on the stack when a callback should be delivered.
    bool lua_hinge_prepare_callback(lua_State *L);
    bool lua_hinge_has_pending_update(lua_State *L);
    
#ifdef __cplusplus
}
#endif

#endif


