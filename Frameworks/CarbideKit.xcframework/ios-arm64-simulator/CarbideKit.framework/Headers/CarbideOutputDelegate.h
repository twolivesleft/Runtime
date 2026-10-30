//
//  CarbideOutputDelegate.h
//  Carbide
//
//  Created by Sim Saens on 14/12/2022.
//  Copyright © 2022 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CarbideOutputDelegate <NSObject>
    
- (void) logMessage:(NSString*)message;
- (void) logWarning:(NSString*)message;
- (void) logError:(NSString*)message;

- (void) clearOutput;

@end

