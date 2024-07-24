//
//  ParameterData.h
//  Runtime
//
//  Created by Simeon on 19/11/12.
//  Copyright (c) 2012 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@class ParameterCell;
@class CodeaLuaState;

typedef NS_ENUM(NSInteger, ParameterDataType) {
    ParameterDataTypeNumber,
    ParameterDataTypeColor,
    ParameterDataTypeText,
    ParameterDataTypeBoolean,
    ParameterDataTypeWatch,
    ParameterDataTypeFunction
};

@interface ParameterData : NSObject
@property (readonly, nonatomic) ParameterDataType type;
@property (strong, nonatomic) NSString *name;
@property (assign, nonatomic) int callback;
@property (readonly, nonatomic) BOOL shouldRegisterDataWhenCreated;
- (void) setDataFromObject:(id)obj;

- (ParameterCell*) createParameterCellInTable:(UITableView*)tableView;

- (void) registerDataWithCodeaLuaState:(CodeaLuaState*)luaState;
- (BOOL) updateFromCodeaLuaState:(CodeaLuaState*)luaState;

- (void) performCallback:(CodeaLuaState*)luaState;
- (void) unrefCallback:(CodeaLuaState*)luaState;
@end

@interface NumericParameterData : ParameterData
@property (assign, nonatomic) CGFloat min;
@property (assign, nonatomic) CGFloat max;
@property (assign, nonatomic) CGFloat value;
@property (assign, nonatomic) BOOL isInteger;
@end

@interface ColorParameterData : ParameterData
@property (assign, nonatomic) CGFloat red;
@property (assign, nonatomic) CGFloat green;
@property (assign, nonatomic) CGFloat blue;
@property (assign, nonatomic) CGFloat alpha;
@end

@interface TextParameterData : ParameterData
@property (strong, nonatomic) NSString *text;
@end

@interface BooleanParameterData : ParameterData
@property (assign, nonatomic) BOOL value;
@end

@interface WatchParameterData : ParameterData
@property (strong, nonatomic) NSString *expression;
@property (strong, nonatomic) NSString *result;
@end

@interface FunctionParameterData : ParameterData
@end
