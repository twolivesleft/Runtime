//
//  AssetPack+Shader.h
//  Runtime
//
//  Created by Simeon on 24/08/13.
//  Copyright (c) 2013 Two Lives Left. All rights reserved.
//

#import <RuntimeKit/AssetPack.h>
#import <RuntimeKit/ShaderBundle.h>

@interface AssetPack (Shader)

- (void) createShaderNamed:(NSString*)shaderName withTemplate:(ShaderBundle*)shaderTemplate completion:(void (^)(ShaderBundle*))completion;
- (void) createDefaultShaderNamed:(NSString*)shaderName completion:(void (^)(ShaderBundle*))completion;

- (ShaderBundle*) shaderNamed:(NSString*)name;

@end
