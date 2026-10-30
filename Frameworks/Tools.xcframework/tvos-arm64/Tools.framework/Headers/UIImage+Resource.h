//
//  UIImage+Resource.h
//  Tools
//
//  Created by Simeon on 12/12/12.
//  Copyright (c) 2012 Two Lives Left. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resource)

+ (UIImage*) imageWithResourceNamed:(NSString*)res width:(CGFloat)width height:(CGFloat)height page:(NSUInteger)page;

/// Bakes an image's EXIF rotation into its pixels, returning it unchanged when
/// there is nothing to do.
+ (UIImage*) imageWithUprightOrientation:(UIImage*)image;

@end
