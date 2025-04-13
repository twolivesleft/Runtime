//
//  AssetContentStorage.h
//  RuntimeKit
//
//  Created by Simeon Saint-Saens on 24/1/20.
//  Copyright © 2020 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AssetContent;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AssetContentListMode) {
    AssetContentListModeOriginal,
    AssetContentListModeSafe,
    AssetContentListModeAll,
};

@interface AssetContentStorage : NSObject

@property (nonatomic, readonly) NSInteger count;

- (instancetype) init;

- (nullable AssetContent*) contentForName:(const char *)name;
- (nullable AssetContent*) contentForSafeName:(const char *)name;

- (void) storeContent:(id)content forName:(const char *)name safeName:(const char *)safeName;

- (nullable NSString *) safeNameForName:(const char *)name;

- (NSArray<NSString*>*) listContent:(AssetContentListMode)mode;

//Swift compatibility

- (nullable AssetContent*) nsContentForName:(NSString *)name;
- (nullable AssetContent*) nsContentForSafeName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
