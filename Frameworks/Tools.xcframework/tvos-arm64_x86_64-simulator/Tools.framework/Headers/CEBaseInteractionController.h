//
//  CEBaseInteractionController.h
//  ViewControllerTransitions
//
//  Created by Colin Eberhardt on 10/09/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef UIViewController *(^CEFetchControllerForPresentation)(void);

/**
 An enumeration that describes the navigation operation that an interaction controller should initiate.
 */
typedef NS_ENUM(NSInteger, CEInteractionOperation) {
    /**
     Indicates that the interaction controller should start a navigation controller 'pop' navigation.
     */
    CEInteractionOperationPush,
    CEInteractionOperationPop,
    /**
     Indicates that the interaction controller should initiate a modal 'present' or 'dismiss'.
     */
    CEInteractionOperationPresent,
    CEInteractionOperationDismiss,
    /**
     Indicates that the interaction controller should navigate between tabs.
     */
    CEInteractionOperationTab
};

/**
 A base class for interaction controllers that can be used with navigation controllers to perform pop operations, or with view controllers that have been presented modally to perform dismissal.
 */
@interface CEBaseInteractionController : UIPercentDrivenInteractiveTransition

/**
 Connects this interaction controller to the given view controller.
 @param viewController The view controller which this interaction should add a gesture recognizer to.
 @param operation The operation that this interaction initiates when.
 @param action called to retrieve the view controller to present
*/
- (void)wireToViewController:(UIViewController*)viewController forOperation:(CEInteractionOperation)operation fetchBlock:(CEFetchControllerForPresentation)action;

/**
 This property indicates whether an interactive transition is in progress.
 */
@property (nonatomic, assign) BOOL interactionInProgress;

@end
