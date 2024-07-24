//
//  CustomProjectIcon.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 10/10/11.
//  Copyright (c) 2011 Developer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomProjectIcon : UIView

- (instancetype) initWithProjectName:(NSString*)name;
- (instancetype) initWithProjectIcon:(UIImage*)icon;

@end

NS_ASSUME_NONNULL_END
