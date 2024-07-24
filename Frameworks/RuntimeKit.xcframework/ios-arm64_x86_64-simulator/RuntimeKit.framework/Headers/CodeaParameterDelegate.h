//
//  CodeaParameterDelegate.h
//  Runtime
//
//  Created by Sim Saens on 22/7/2024.
//  Copyright © 2024 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CodeaViewController;
@class ParameterData;

NS_ASSUME_NONNULL_BEGIN

@protocol CodeaParameterDelegate

- (void) codea:(CodeaViewController*)codea didCreateParameter:(ParameterData*)data;
- (void) codea:(CodeaViewController*)codea didUpdateParameter:(ParameterData*)data;
- (void) codeaDidRefreshAllParameters:(CodeaViewController*)codea;
- (void) codeaDidClearParameters:(CodeaViewController*)codea;
- (NSMutableArray*) codeaGetAllParameters:(CodeaViewController*)codea;
- (void) codea:(CodeaViewController*)codea setParameterFromData:(NSDictionary*)data;

@end

NS_ASSUME_NONNULL_END
