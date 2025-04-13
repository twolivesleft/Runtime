//
//  SSEdgeSwipeInteractionController.h
//  Tools
//
//  Created by Simeon on 20/11/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#import <Tools/CEBaseInteractionController.h>

#pragma clang assume_nonnull begin

typedef BOOL(^SSEdgeSwipeShouldDismiss)(UIViewController*);

@interface SSEdgeSwipeInteractionController : CEBaseInteractionController

@property (nonatomic, assign) UIRectEdge edge;

#if !TARGET_OS_VISION && !TARGET_OS_TV
@property (nonatomic, readonly) UIScreenEdgePanGestureRecognizer *gesture;
#endif

@property (nullable, nonatomic, copy) SSEdgeSwipeShouldDismiss shouldDismiss;

#pragma clang assume_nonnull end

@end


