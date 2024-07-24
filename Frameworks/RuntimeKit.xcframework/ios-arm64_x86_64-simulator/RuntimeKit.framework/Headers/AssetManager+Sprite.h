//
//  AssetManager+Sprite.h
//  Runtime
//
//  Created by Simeon on 27/07/13.
//  Copyright (c) 2013 Two Lives Left. All rights reserved.
//

#import <RuntimeKit/AssetManager.h>

@class CCTexture2D;
@class TextureCache;

@interface AssetManager (Sprite)

- (CCTexture2D*) spriteTextureFromPath:(NSString*)spritePath cache:(TextureCache*)cache;
- (CCTexture2D*) spriteTextureFromPath:(NSString*)spritePath width:(CGFloat)width cache:(TextureCache*)cache;
- (CCTexture2D*) spriteTextureFromPath:(NSString*)spritePath width:(CGFloat)width height:(CGFloat)height cache:(TextureCache*)cache;

- (UIImage*) spriteImageFromString:(NSString*)spriteString projectPath:(NSString*)projectPath;
- (UIImage*) spriteImageFromString:(NSString*)spriteString projectPath:(NSString*)projectPath atHeight:(CGFloat)height;
- (UIImage*) spriteImageFromString:(NSString*)spriteString projectPath:(NSString*)projectPath atWidth:(CGFloat)width;

@end
