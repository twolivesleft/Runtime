//
//  RendererDelegate.h
//  Runtime
//
//  Created by Sim Saens on 11/7/2022.
//  Copyright © 2022 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Renderer;

@protocol RendererDelegate <NSObject>

- (void) renderer:(Renderer*)renderer willPause:(BOOL)pause;

@end
