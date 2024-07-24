//
//  Driver.h
//  limbicgl
//
//  Created by Volker Schoenefeld on 6/15/11.
//  Copyright 2011 Limbic Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RendererPlatformSupport.h"

#if TARGET_OS_SUPPORTS_GL
#import <OpenGLES/EAGL.h>
#endif

@class RenderTarget;

#if TARGET_OS_SUPPORTS_GL
@class CAEAGLLayer;
#endif

@protocol Game;
@protocol Driver

@property (nonatomic, weak) id<Game> game;
@property (nonatomic, readonly) dispatch_queue_t queue;

@property (nonatomic, assign) NSInteger preferredFPS;

// Activates the automatic rendering of the game
- (void) startAnimation;
// Stops the automatic rendering
- (void) stopAnimation;

- (BOOL) isAnimating;

// Releases all the allocated assets and modules
- (void) teardown;

#if TARGET_OS_SUPPORTS_GL
// Called each time the underlying UIView is re-layouted
- (void) setLayer:(CAEAGLLayer*)layer;
#endif

- (void) runBlock:(dispatch_block_t)block;

#if TARGET_OS_SUPPORTS_GL
- (EAGLContext*) context;
#endif

@end
