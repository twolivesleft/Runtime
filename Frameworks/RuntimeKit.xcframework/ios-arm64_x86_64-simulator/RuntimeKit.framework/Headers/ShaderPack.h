//
//  ShaderPack.h
//  Codea
//
//  Created by Simeon on 1/10/12.
//  Copyright (c) 2012 Developer. All rights reserved.
//

#import <RuntimeKit/RuntimeBundle.h>

@class ShaderBundle;

@interface ShaderPack : RuntimeBundle

@property (nonatomic,readonly) NSUInteger shaderCount;
@property (nonatomic,readonly) NSString *description;
@property (nonatomic,readonly) UIImage *icon;

@property (nonatomic,assign) BOOL userPack;

+ (ShaderPack*) shaderPackWithPath:(NSString*)path;
- (id) initWithPath:(NSString*)path;

- (NSUInteger) indexOfShaderBundle:(ShaderBundle*)bundle;
- (ShaderBundle*) shaderBundleAtIndex:(NSUInteger)index;
- (ShaderBundle*) shaderBundleWithName:(NSString*)name;
- (NSString*) shaderBundlePathWithName:(NSString*)shaderName;

- (NSArray*) shadersAtIndices:(NSIndexSet*)set;

- (BOOL) deleteShaderAtIndex:(NSUInteger)index andReload:(BOOL)reload;
- (BOOL) deleteShaderAtIndex:(NSUInteger)index;
- (BOOL) deleteShadersAtIndices:(NSIndexSet*)set;

@end
