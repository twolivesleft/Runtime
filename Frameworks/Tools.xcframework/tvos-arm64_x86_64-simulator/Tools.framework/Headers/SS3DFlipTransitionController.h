//
//  ProjectFlipTransitionController.h
//  Codea
//
//  Created by Simeon on 9/08/2014.
//  Copyright (c) 2014 Developer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SS3DFlipTransitionController : NSObject<UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, weak) UIView *sourceView;

@property (nonatomic, assign) CGSize destinationSize;

@property (nonatomic, assign) UINavigationControllerOperation navOperation;

@end
