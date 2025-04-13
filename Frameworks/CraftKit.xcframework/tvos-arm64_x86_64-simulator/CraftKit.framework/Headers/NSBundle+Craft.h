//
//  NSBundle+Craft.h
//  Craft
//
//  Created by John Millard on 17/06/2016.
//  Copyright © 2016 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RuntimeLocalizedString(key, comment) \
[[NSBundle runtimeResourcesBundle] localizedStringForKey:(key) value:(comment) table:nil]

extern NSString *const CraftKitBundleIdentifier;

@interface NSBundle (Craft)

+ (NSBundle*) craftResourcesBundle;

@end
