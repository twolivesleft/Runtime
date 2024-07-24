//
//  RemoteAssetPack.h
//  Runtime
//
//  Created by John Millard on 2/09/13.
//  Copyright (c) 2013 Two Lives Left. All rights reserved.
//

#import <RuntimeKit/AssetPack.h>

typedef enum
{
    kRemoteAssetPackStateNotDownloaded=0,
    kRemoteAssetPackStatePartiallyDownloaded,
    kRemoteAssetPackStateFullyDownloaded
} RemoteAssetPackState;

@interface RemoteAssetPack : AssetPack

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) RemoteAssetPackState state;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) NSData *resumeData;

- (NSString*) archivePath;

@end
