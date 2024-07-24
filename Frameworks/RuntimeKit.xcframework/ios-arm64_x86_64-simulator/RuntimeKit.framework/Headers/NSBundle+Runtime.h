//
//  NSBundle+Runtime.h
//  Runtime
//
//  Created by Simeon on 8/11/12.
//  Copyright (c) 2012 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RuntimeLocalizedString(key, comment) \
    [[NSBundle runtimeResourcesBundle] localizedStringForKey:(key) value:(comment) table:nil]

extern NSString *const RuntimeKitBundleIdentifier;

@interface NSBundle (Runtime)

+ (NSBundle*) runtimeResourcesBundle;

+ (NSString*) runtimeResourcePathForName:(NSString*)name type:(NSString*)type;

+ (NSString*) runtimeLocalizedString:(NSString*)key comment:(NSString*)comment;

@end
