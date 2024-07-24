//
//  OALWrapper.h
//  Runtime
//
//  Created by Simeon on 14/12/2015.
//  Copyright © 2015 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class OALAudioTrackWrapper;

@interface OALWrapper : NSObject

+ (void) configureSessionForPlayback;
+ (void) configureSessionForPlaybackAndRecord;

+ (OALAudioTrackWrapper *) playBackground:(NSString *)path;
+ (void) playEffect:(NSString *)path;
+ (void) stopBackground;

@end

@interface OALAudioTrackWrapper : NSObject

@property (nonatomic, weak) id<AVAudioPlayerDelegate> delegate;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, readonly) NSTimeInterval duration;

@end
