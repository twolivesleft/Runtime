//
//  ToolsDefines.h
//  Tools
//
//  Created by Simeon on 11/12/12.
//  Copyright (c) 2012 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#	define DebugLog(...) NSLog(__VA_ARGS__)
#else
#	define DebugLog(...) do {} while(0)
#endif
