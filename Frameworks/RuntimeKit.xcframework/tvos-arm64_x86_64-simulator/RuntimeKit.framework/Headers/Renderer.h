//
//  Renderer.h
//  LimbicGL
//
//  Created by Volker Schönefeld on 6/12/11.
//  Copyright 2011 Limbic Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RendererPlatformSupport.h"

#if TARGET_OS_SUPPORTS_GL
@class CAEAGLLayer;
@class EAGLContext;
#endif

@class UIImage;
@class RenderTarget;

@protocol Game;
@protocol Driver;
@protocol RendererDelegate;

@interface Renderer: NSObject

@property (nonatomic, weak) id<Game> game;
@property (nonatomic, weak) id<RendererDelegate> delegate;
@property (nonatomic, strong) id<Driver> driver;
@property (nonatomic, strong) RenderTarget *rendertarget;

// Called whenever the underlying UIView is re-layouted
#if TARGET_OS_SUPPORTS_GL
- (void)setLayer:(CAEAGLLayer *)layer;
#endif
// start animating the scene at 60hz
- (void)startAnimation;
// stop the animation
- (void)stopAnimation;

- (BOOL)isAnimating;

- (UIImage*) screenshot:(CGFloat)contentScaleFactor;

- (void) runBlock:(void (^)(void))block;
- (void) runGLBlock:(void (^)(void))block;

#pragma mark - GL Related

- (void) bindDrawable;
- (void) setViewport;

#if TARGET_OS_SUPPORTS_GL
- (EAGLContext*) eaglContext;
#endif

@end
