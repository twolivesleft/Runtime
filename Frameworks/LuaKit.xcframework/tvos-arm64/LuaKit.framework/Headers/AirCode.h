//
//  AirCode.h
//  LuaKit
//
//  Created by Sim Saens on 30/4/2023.
//

#ifndef Lua_AirCode_h
#define Lua_AirCode_h

#ifdef __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>
#import <LuaKit/lua.h>
#import <LuaKit/lauxlib.h>

void luamodule_airCode(lua_State * _Nonnull L);

@protocol LuaAirCodeInterface

@property (nonatomic, readonly) NSInteger debugMessageCount;

- (void) sendDebugMessage:(nonnull NSString*)message;
- (nullable NSString*) receiveDebugMessage:(nonnull lua_State*)L;

@end

@interface LuaAirCodeProvider: NSObject

+ (void) setAirCodeInstance:(nullable id<LuaAirCodeInterface>)instance;
+ (NSInteger) messageCount;
+ (void) send:(nonnull NSString*)message;
+ (nullable NSString*) receive:(nonnull lua_State*)L;
   
@end

#ifdef __cplusplus
}
#endif

#endif
