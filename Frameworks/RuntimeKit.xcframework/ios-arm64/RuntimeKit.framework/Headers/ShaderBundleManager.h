//
//  ShaderBundleManager.h
//  Codea
//
//  Created by Simeon on 1/10/12.
//  Copyright (c) 2012 Developer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ShaderBundle;
@class ShaderPack;

@interface ShaderBundleManager : NSObject

@property (nonatomic, readonly) NSArray *includedShaderPacks;
@property (nonatomic, readonly) NSArray *userShaderPacks;
@property (nonatomic, readonly) NSArray *availableShaderPacks;

@property (nonatomic, readonly) ShaderPack *templateShaders;

+ (instancetype) sharedInstance;

- (NSString*) shaderBundlePathFromString:(NSString*)shaderString;

- (ShaderPack*) shaderPackFromString:(NSString*)shaderString;
- (ShaderBundle*) shaderBundleFromString:(NSString*)shaderString;

- (BOOL) shaderName:(NSString*)name existsInPack:(ShaderPack*)pack;
- (ShaderBundle*) createBlankShaderNamed:(NSString*)name inPack:(ShaderPack*)pack;
- (ShaderBundle*) createDefaultShaderNamed:(NSString*)name inPack:(ShaderPack*)pack;
- (ShaderBundle*) createShaderNamed:(NSString*)name withTemplate:(ShaderBundle*)shaderTemplate inPack:(ShaderPack*)pack;

@end
