//
//  AssetManager.h
//  Runtime
//
//  Created by John Millard on 15/06/13.
//  Copyright (c) 2013 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <RuntimeKit/AssetPack.h>

NS_ASSUME_NONNULL_BEGIN

//#define kRemoteAssetPackURL @"http://localhost:8888/AssetPacks/"
//#define kRemoteAssetPackURL @"http://twolivesleft.com/Codea/AssetPacks/"
//#define kRemoteAssetPackURL @"https://codea.io/assets/"
#define kRemoteAssetPackURL @"https://codea-frameworks.s3.us-west-2.amazonaws.com/assets/"

#define kAssetManagerAccessedUnavailableAssetNotification @"AssetManagerAccessedUnavailableAssetNotification"

extern NSString *const kAssetFolderKey;
extern NSString *const kAssetProjectKey;
extern NSString *const kAssetSpritesKey;
extern NSString *const kAssetMusicKey;
extern NSString *const kAssetSoundsKey;
extern NSString *const kAssetShadersKey;
extern NSString *const kAssetTextKey;
extern NSString *const kAssetModelsKey;
extern NSString *const kAssetUnknownKey;


@class AssetManager;
@class RemoteAssetPack;
@class Project;

@protocol AssetManagerDelegate <NSObject>

@optional
- (void) assetManagerDidRefreshRemoteAssetPacks:(AssetManager*)assetManager;
- (void) assetManager:(AssetManager*)assetManager remoteAssetPackDownloadProgressDidUpdate:(RemoteAssetPack*)remoteAssetPack;
- (void) assetManager:(AssetManager*)assetManager remoteAssetPackDownloadDidComplete:(RemoteAssetPack*)remoteAssetPack;
- (void) assetManager:(AssetManager*)assetManager remoteAssetPackDownloadDidCancel:(RemoteAssetPack*)remoteAssetPack;
- (void) assetManager:(AssetManager*)assetManager remoteAssetPackDownloadDidFail:(RemoteAssetPack*)remoteAssetPack withError:(NSError*)error;

@end

@interface AssetManager : NSObject

@property (nonatomic, readonly, nonnull) NSArray<AssetPack*> *includedAssetPacks;
@property (nonatomic, readonly, nonnull) NSArray<AssetPack*> *unavailableAssetPacks;

@property (nonatomic, readonly, nonnull) NSString *downloadsPath;
@property (nonatomic, readonly, nonnull) NSString *documentsPath;

@property (nonatomic, weak, nullable) id<AssetManagerDelegate> delegate;

@property (nonatomic, assign) BOOL allowProjectAssetPack;
@property (nonatomic, assign) BOOL allowRemoteAssetPacks;

+ (nonnull instancetype) sharedInstance;

+ (nonnull NSString*) assetPackExtension;
+ (nonnull NSString*) assetPackGroupName;

- (void) refreshUserAssetPacks;

- (nonnull NSArray<AssetPack*>*) availableAssetPacksWithProjectPath:(nullable NSString*)projectPath;
- (nonnull NSArray<AssetPack*>*) userAssetPacksWithProjectPath:(nullable NSString*)projectPath;

- (nonnull NSArray*) availableAssetPacksOfTypes:(nonnull NSArray*)types withProjectPath:(nullable NSString*)projectPath;
- (nonnull NSArray*) unavailableAssetPacksOfTypes:(nonnull NSArray*)types;

- (nullable AssetPack*) assetPackNamed:(nonnull NSString*)name projectPath:(nullable NSString*)projectPath;;
- (nullable AssetPack*) assetPackFromPath:(nonnull NSString*)path;
- (nullable AssetPack*) assetPackFromAssetString:(nonnull NSString*)assetString projectPath:(NSString*)projectPath;

- (nullable NSString*) filePathFromAssetString:(nonnull NSString*)assetString projectPath:(nullable NSString*)projectPath mustExist:(BOOL)exist;
- (nullable NSString*) filePathFromAssetString:(nonnull NSString*)assetString projectPath:(nullable NSString*)projectPath supportedExtensions:(nullable NSArray*)extensions mustExist:(BOOL)exist;
- (nullable id) assetFromAssetString:(nonnull NSString*)assetString projectPath:(nullable NSString*)projectPath;

- (nonnull NSArray*) assetTypesSupportingUserCreation;
- (nonnull NSArray*) supportedExtensionsForPackType:(nonnull NSString *)type;

- (void) resetCacheProjectPath:(nullable NSString*)projectPath;

- (void) refreshRemoteAssetPacks;
- (void) downloadAssetPack:(nonnull RemoteAssetPack*)remoteAssetPack;
- (void) cancelAssetPackDownload:(nonnull RemoteAssetPack*)remoteAssetPack;

- (void) addCustomAssetPack:(nonnull AssetPack*)pack;

+ (nullable NSURL*) urlForRemotePath:(nonnull NSString*)path;

+ (nonnull NSArray*) supportedRetinaScales;
+ (nonnull NSString*) appendScale:(CGFloat)scale toPath:(nonnull NSString*)path;

@end

NS_ASSUME_NONNULL_END
