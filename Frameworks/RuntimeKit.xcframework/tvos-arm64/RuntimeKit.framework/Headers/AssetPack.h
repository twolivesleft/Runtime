//
//  AssetPack.h
//  Runtime
//
//  Created by John Millard on 15/06/13.
//  Copyright (c) 2013 Two Lives Left. All rights reserved.
//

#import <RuntimeKit/RuntimeBundle.h>

typedef void(^AssetPackWriter)(NSURL*__nonnull);

@interface AssetPack : RuntimeBundle

@property (nonatomic, assign) BOOL userPack;

// Different common filters used by categories
@property (nonnull, nonatomic, readonly) NSArray *folders;
@property (nonnull, nonatomic, readonly) NSArray *spriteFiles;
@property (nonnull, nonatomic, readonly) NSArray *soundFiles;
@property (nonnull, nonatomic, readonly) NSArray *musicFiles;
@property (nonnull, nonatomic, readonly) NSArray *textFiles;
@property (nonnull, nonatomic, readonly) NSArray *modelFiles;
@property (nonnull, nonatomic, readonly) NSString *resolvedPath;

- (nonnull NSArray*) filterFilesWithExtensions:(nonnull NSArray*)extensions;
- (BOOL) supportsAssetType:(nonnull NSString*)assetType;

- (nonnull NSArray*) assetNames;
- (nonnull NSArray*) filterAssetNamesWithExtensions:(nonnull NSArray*)extensions;

- (BOOL) deleteAssetAtIndex:(NSInteger)index andReload:(BOOL)reload;
- (BOOL) deleteAssetAtIndex:(NSInteger)index;
- (BOOL) deleteAssetsAtIndices:(nonnull NSIndexSet*)set;

- (BOOL) addAssetFromPath:(nonnull NSString*)path;
- (BOOL) addAssetFromPath:(nonnull NSString*)path shouldOverwrite:(BOOL)overwrite;
- (BOOL) addAssetsFromPaths:(nonnull NSArray*)paths shouldOverwrite:(BOOL)overwrite;
- (BOOL) containsDuplicateAsset:(nonnull NSString*)path;

- (BOOL) startAccessingSecurityScopedResource;
- (void) stopAccessingSecurityScopedResource;

- (void) createFolder:(nonnull NSString*)folderName;
- (void) writeAsset:(nonnull NSString*)fileName writer:(nonnull AssetPackWriter)writer;
- (nonnull AssetPack*) childAssetPackAtPath:(nonnull NSString*)path;

- (nullable NSString*) assetPathForKey:(nonnull NSString*)key limitedToExtensions:(nonnull NSArray*)extensions mustExist:(BOOL)exist;

+ (nonnull NSArray*) supportedExtensionsFromAssetTypes:(nonnull NSArray *)types;
+ (nonnull NSArray*) supportedExtensionsFromAssetType:(nonnull NSString *)type;

+ (nonnull NSString*) typeFromAssetExtension:(nonnull NSString*)ext;
+ (nonnull NSString*) typeFromAssetFile:(nonnull NSString*)path;

+ (nonnull NSArray *) allFileExtensions;
+ (nonnull NSArray *) assetFileExtensions;
+ (nonnull NSArray *) spriteFileExtensions;
+ (nonnull NSArray *) soundFileExtensions;
+ (nonnull NSArray *) musicFileExtensions;
+ (nonnull NSArray *) shaderFileExtensions;
+ (nonnull NSArray<NSString*> *) textFileExtensions;
+ (nonnull NSArray *) modelFileExtensions;

@end
