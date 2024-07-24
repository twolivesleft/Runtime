//
//  CodeaLuaError.h
//  RuntimeKit
//
//  Created by Sim Saens on 11/7/2022.
//  Copyright © 2022 Two Lives Left. All rights reserved.
//

#ifndef CodeaLuaError_h
#define CodeaLuaError_h

typedef struct LuaError
{
    NSUInteger lineNumber;
    NSUInteger referringLine;
    __unsafe_unretained NSString* errorMessage;
} LuaError;

#endif /* CodeaLuaError_h */
