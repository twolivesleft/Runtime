//
//  AssetPack+Icon.h
//  Runtime
//
//  Created by Simeon on 7/07/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#import <RuntimeKit/AssetPack.h>

@interface AssetPack (Icon)

@property (nonatomic, readonly) UIImage *iconImage;

- (UIImage *) iconImageAtHeight:(CGFloat)height;
- (UIImage *) iconImageAtWidth:(CGFloat)width;

@end
