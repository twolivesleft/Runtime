//
//  EAGLView.h
//  OpenGLES_iPhone
//
//  Created by mmalc Crawford on 11/18/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Renderer;
@class EAGLContext;
@class EAGLView;

@protocol EAGLViewLayoutDelegate <NSObject>

- (void) eaglViewWillLayoutSubviews:(EAGLView*)view;

@end

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView

@property (nonatomic, weak) Renderer *renderer;

@property (nonatomic, weak) id<EAGLViewLayoutDelegate> layoutDelegate;

@end
