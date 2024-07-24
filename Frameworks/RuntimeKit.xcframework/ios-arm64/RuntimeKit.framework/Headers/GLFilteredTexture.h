//
//  GLFilteredTexture.h
//  Codea
//
//  Created by Dylan Sale on 16/09/12.
//  Copyright (c) 2012 Developer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <RuntimeKit/RendererPlatformSupport.h>

#if TARGET_OS_SUPPORTS_GL
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES3/gl.h>
#endif

@protocol GLFilteredTexture <NSObject>
@required
- (void) setAntiAliasTexParameters;
- (void) setAliasTexParameters;

#if TARGET_OS_SUPPORTS_GL
/** texture name */
@property(nonatomic,readonly) GLuint name;
#endif

/** width in pixels */
@property(nonatomic,readonly) NSUInteger pixelsWide;
/** hight in pixels */
@property(nonatomic,readonly) NSUInteger pixelsHigh;

/** scale factor (for retina, this should be 2.0 if the image is @2x) */
@property(nonatomic,assign) CGFloat scale;

@end
