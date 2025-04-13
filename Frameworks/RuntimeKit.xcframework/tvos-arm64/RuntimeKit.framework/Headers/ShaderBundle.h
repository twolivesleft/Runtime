//
//  ShaderBundle.h
//  Codea
//
//  Created by Simeon on 30/09/12.
//  Copyright (c) 2012 Developer. All rights reserved.
//

#import <RuntimeKit/RuntimeBundle.h>

struct lua_State;

@interface ShaderBundle : RuntimeBundle

@property (nonatomic,readonly) id vertexShader;
@property (nonatomic,readonly) id fragmentShader;
@property (nonatomic,strong) UIImage *icon;

@property (nonatomic,strong) NSArray *bufferNames;
@property (nonatomic,strong) NSArray *buffers;

@property (nonatomic,readonly) BOOL isLoaded;

+ (id) shader;
+ (id) shaderWithPath:(NSString *)path;
- (id) initWithPath:(NSString *)path;

- (NSString*) contentsForBufferAtIndex:(NSUInteger)bufferIndex;
- (NSString*) contentsForVertexBuffer;
- (NSString*) contentsForFragmentBuffer;

- (NSString*) vertexShaderDiskContents;
- (NSString*) fragmentShaderDiskContents;

- (void) loadFromShader:(ShaderBundle*)shader;

- (BOOL) save;

- (void) unload;
- (void) load;

- (int) pushToLuaState:(struct lua_State*)L;

@end
