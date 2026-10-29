//
//  SceneDataSource.h
//  SceneDataSource
//
//  Created by John Millard on 30/7/21.
//  Copyright © 2021 John Millard. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CarbideKit/CarbideKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SceneDataSource : NSObject
{

}

@property (readonly) BOOL loaded;

- (instancetype)initWithPath:(NSURL*)path;
- (instancetype)initWithString:(NSString*)contents;

+ (void)createDefault3dSceneAtPath:(NSURL*)path;
+ (void)createDefault2dSceneAtPath:(NSURL*)path;

- (nullable NSString*)makeSnapshot;
- (BOOL)applySnapshot:(NSString*)snapshot;


@end

NS_ASSUME_NONNULL_END
