//
//  SSImageCache.h
//  Tools
//
//  Created by Simeon on 19/01/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Tools/UIImageView+AFNetworking.h>

@interface SSImageCache : NSCache<AFImageCache>

- (UIImage *)cachedImageForKey:(NSString *)key;

- (void)cacheImage:(UIImage *)image
            forKey:(NSString *)key;

@end
