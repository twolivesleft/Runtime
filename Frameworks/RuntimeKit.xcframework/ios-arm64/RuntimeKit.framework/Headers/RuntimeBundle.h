//
//  Bundle.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 2/10/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RuntimeBundle : NSObject
{
@protected
    NSString            *bundlePath;
    NSArray             *validFileTypes;
    NSMutableArray      *files;
    NSString            *name;
    NSMutableDictionary *info;
}

@property (nonnull, atomic, strong)       NSString            *bundlePath;
@property (nonnull, nonatomic, readonly)    NSArray             *files;
@property (nonnull, nonatomic, strong)      NSMutableDictionary *info;
@property (nonnull, nonatomic, readonly)    NSString            *name;
@property (nonnull, nonatomic, readonly)    NSString            *localizedName;
@property (nullable, nonatomic, readonly)   UIImage             *icon;
@property (nullable, nonatomic, readonly)    NSArray             *validFileTypes;
@property (nonnull, nonatomic, readonly)    NSDate              *lastModifiedDate;

+ (nonnull instancetype) bundleWithPath:(nonnull NSString*)path;
+ (nonnull instancetype) bundleWithPath:(nonnull NSString*)path validFileTypes:(nullable NSArray*)validExt;

- (nonnull instancetype) initWithPath:(nonnull NSString*)path validFileTypes:(nullable NSArray*)validExt;

- (nonnull NSString*) fileNameFromBundlePath:(nonnull NSString*)path;
- (nullable NSString*) fileNameAtIndex:(NSUInteger)index;

- (void) createIconFromImage:(nonnull UIImage *)icon;

- (void) updateBundlePath:(nonnull NSString*)updatedPath;

- (void) reloadFilesFromBundlePath;
- (void) reloadFilesFromPath:(nonnull NSString*)bundlePath;

- (nonnull NSMutableDictionary*) defaultInfoDictionary;

- (BOOL) isFileValid:(nonnull NSString*)path;

- (void) invalidateLastModifiedDate;
- (void) updateLastModifiedDate:(nonnull NSDate *)date updateFileAttributes:(BOOL)update;
- (void) updateLastModifiedDate:(nonnull NSDate *)date;

// For subclasses

- (void) willReloadFiles;
- (void) didLoadFile:(nonnull NSString *)path;
- (void) didReloadFiles;

@end
