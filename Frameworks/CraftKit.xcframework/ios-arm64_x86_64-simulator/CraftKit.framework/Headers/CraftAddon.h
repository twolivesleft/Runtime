//
//  CraftAddon.h
//  Craft
//
//  Created by John Millard on 17/06/2016.
//  Copyright © 2016 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CodeaAddon;

FOUNDATION_EXPORT NSString *const kCraftAddonKey;

@interface CraftAddon : NSObject <CodeaAddon>

//Can be used to prevent the initialization of bullet
+ (void) setBulletPhysicsSystemEnabled:(BOOL)enabled;

+ (void) applicationDidLaunch;

@end
