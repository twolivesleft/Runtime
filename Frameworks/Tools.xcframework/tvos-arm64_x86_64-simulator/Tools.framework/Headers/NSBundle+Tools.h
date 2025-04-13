//
//  NSBundle+Tools
//  Runtime
//
//  Created by Simeon on 8/11/12.
//  Copyright (c) 2012 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString  * _Nonnull const ToolsBundleIdentifier;

#define ToolsLocalizedString(key, comment) \
    [[NSBundle toolsResourcesBundle] localizedStringForKey:(key) value:(comment) table:nil]

@interface NSBundle (Tools)

+ (nonnull NSBundle*) toolsResourcesBundle;

+ (nonnull NSString*) pathForPreferredLanguage:(nonnull NSString*)path;

@end
