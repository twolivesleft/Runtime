//
//  ProjectAssetPack.h
//  Codea
//
//  Created by Simeon on 28/08/2014.
//  Copyright (c) 2014 Developer. All rights reserved.
//

#import <RuntimeKit/AssetPack.h>

@class Project;

@interface ProjectAssetPack : AssetPack

@property (nonatomic, readonly) BOOL allowImportAll;
@property (nonatomic, readonly) Project *project;
@property (nonatomic, readonly) NSString *projectName;
@property (nonatomic, readonly) NSString *collectionName;
@property (nonatomic, readonly) BOOL canDisplayIcon;

- (id) initWithProject:(Project *)project;
- (id) initWithProject:(Project *)project collectionName:(NSString*)collectionName allowImportAll:(BOOL)allowImportAll canDisplayIcon:(BOOL)canDisplayIcon;

@end
