//
//  NSBundle+Lua.h
//  Lua
//
//  Created by Sim Saens on 21/8/2022.
//

#import <Foundation/Foundation.h>

extern NSString *const LuaBundleIdentifier;

@interface NSBundle (Lua)

+ (NSBundle*) luaResourcesBundle;

+ (NSString*) luaResourcePathForName:(NSString*)name type:(NSString*)type;

@end
