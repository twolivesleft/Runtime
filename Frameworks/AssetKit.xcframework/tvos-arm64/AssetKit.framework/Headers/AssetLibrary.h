//
//  AssetLibrary.h
//  AssetKit
//
//  Created by Jean-Francois Perusse on 2024-02-10.
//

#pragma once

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

NSURL* CreateURLWithResolvingStaleBookmarkURL(NSURL* bookmarkURL, NSError** error);

#ifdef __cplusplus
}
#endif
