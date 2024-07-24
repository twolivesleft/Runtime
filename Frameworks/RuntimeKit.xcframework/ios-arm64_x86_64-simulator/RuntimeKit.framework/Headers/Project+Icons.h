//
//  Project+Icons.h
//  Codea
//
//  Created by Simeon on 18/07/12.
//  Copyright (c) 2012 Developer. All rights reserved.
//

#import <RuntimeKit/Project.h>

@interface Project (Icons)

@property (nonatomic, readonly, nullable) UIImage *iconImage;
@property (nonatomic, readonly, nonnull) UIView *icon;
@property (nonatomic, readonly) BOOL hasPDFIcon;
@property (nonatomic, readonly, nullable) UIColor *iconTintColor;

- (void) setIconTintColor:(nullable UIColor*)color;

@end
