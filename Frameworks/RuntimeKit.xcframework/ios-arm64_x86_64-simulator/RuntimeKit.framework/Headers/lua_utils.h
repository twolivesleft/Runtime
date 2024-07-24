//
//  lua_utils.h
//  Runtime
//
//  Created by Simeon on 28/07/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#ifndef Runtime_lua_utils_h
#define Runtime_lua_utils_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C"
{
#endif

    struct lua_State;
    
    //MARK: Argument count validation
    
    bool assertMinimumRequiredArgumentCount(struct lua_State *L, int count);
    
    bool assertRequiredArgumentCount(struct lua_State *L, int count);

    //MARK: Null checking    
    
    bool hasNulls(const char* str, size_t len);
    
#ifdef __cplusplus
}
#endif

#endif
