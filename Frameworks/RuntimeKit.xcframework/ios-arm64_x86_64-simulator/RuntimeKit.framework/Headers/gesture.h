//
//  gesture.hpp
//  RuntimeKit
//
//  Created by Simeon Saint-Saens on 25/4/20.
//  Copyright © 2020 Two Lives Left. All rights reserved.
//

#ifndef gesture_hpp
#define gesture_hpp

#import <UIKit/UIKit.h>

#include <RuntimeKit/touch.h>

static interaction_state interactionStateFromGestureState(UIGestureRecognizerState gestureState) {
    switch(gestureState) {
        case UIGestureRecognizerStateBegan:
            return INTERACTION_STATE_BEGAN;
        case UIGestureRecognizerStateChanged:
            return INTERACTION_STATE_CHANGED;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            return INTERACTION_STATE_ENDED;
        default:
            return INTERACTION_STATE_INACTIVE;
    }
}

#ifdef __cplusplus
struct Gesture {
    Gesture() :
        location(CGPointZero),
        translation(CGPointZero),
        deltaTranslation(CGPointZero),
        pinchScale(0),
        pinchVelocity(0),
        numberOfTouches(0),
        state(INTERACTION_STATE_INACTIVE),
        modifierFlags(0)
    {}
    
    Gesture(const Gesture& gesture) :
        location(gesture.location),
        translation(gesture.translation),
        deltaTranslation(gesture.deltaTranslation),
        pinchScale(gesture.pinchScale),
        pinchVelocity(gesture.pinchVelocity),
        numberOfTouches(gesture.numberOfTouches),
        state(gesture.state),
        modifierFlags(gesture.modifierFlags)
    {}
    
    Gesture(UIGestureRecognizer *uiGesture, UIView *inView) {
        
        this->state = interactionStateFromGestureState(uiGesture.state);
        
        CGPoint location = [uiGesture locationInView:inView];
        this->location = CGPointMake(location.x, inView.bounds.size.height - location.y);
        this->numberOfTouches = uiGesture.numberOfTouches;
        
        if (@available(iOS 13.4, *)) {
            this->modifierFlags = uiGesture.modifierFlags;
        }
    }
    
    CGPoint location;
    CGPoint translation;
    CGPoint deltaTranslation;
    
    CGFloat pinchScale;
    CGFloat pinchVelocity;
    
    NSInteger numberOfTouches;
    
    interaction_state state;
    
    UIKeyModifierFlags modifierFlags;
    
    CGPoint getLocation() const;
    CGPoint getTranslation() const;
    CGPoint getDeltaTranslation() const;
    
    CGFloat getPinchScale() const;
    CGFloat getPinchVelocity() const;
    
    NSInteger getNumberOfTouches() const;
    interaction_state getState() const;
    
    bool capsLockEnabled() const;
    bool shiftEnabled() const;
    bool controlEnabled() const;
    bool altEnabled() const;
    bool commandEnabled() const;
    bool numPadEnabled() const;
};
#endif

#ifdef __cplusplus
extern "C" {
#endif
    #import <LuaKit/lua.h>

    void luamodule_gesture(lua_State *L);

    #ifdef __cplusplus
    void push_gesture(lua_State *L, Gesture gesture);
    #endif
#ifdef __cplusplus
}
#endif

#endif /* gesture_hpp */
