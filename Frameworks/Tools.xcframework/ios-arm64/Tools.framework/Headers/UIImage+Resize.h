//
//  UIImage+Resize.h
//  Tools
//
//  Created by Simeon on 19/01/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize scaleFactor:(CGFloat)factor;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToWidth:(CGFloat)width;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToHeight:(CGFloat)height;

+ (UIImage *) imageWithView:(UIView *)view;

@end
