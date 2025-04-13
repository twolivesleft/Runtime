//
//  Game.h
//  Runtime
//
//  Created by Dylan Sale on 28/01/2014.
//  Copyright (c) 2014 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Game <NSObject>
@required
- (void) update;
- (void) drawWithDelta:(CFTimeInterval)delta;
@end
