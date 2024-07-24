//
//  SSViewControllerTransitioningDelegate.h
//  Tools
//
//  Created by Simeon on 20/11/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Tools/CEBaseInteractionController.h>
#import <Tools/CEReversibleAnimationController.h>

@interface SSViewControllerTransitioningDelegate : NSObject<UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) CEBaseInteractionController *interactivePresentationController;
@property (nonatomic, strong) CEBaseInteractionController *interactiveDismissalController;

@property (nonatomic, strong) id<UIViewControllerAnimatedTransitioning> animatedPresentationController;
@property (nonatomic, strong) id<UIViewControllerAnimatedTransitioning> animatedDismissalController;

@end
