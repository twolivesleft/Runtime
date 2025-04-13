//
//  CodeaScriptExecute.h
//  Codea
//
//  Created by Simeon Saint-Saëns on 9/20/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RuntimeKit/CodeaLuaState.h>

NS_ASSUME_NONNULL_BEGIN

@class Project;

@protocol ScriptValidateErrorDelegate <NSObject>
- (void) error:(LuaError)error inBuffer:(NSString*)bufferName inProject:(NSString*)projectPath;

- (void) error:(LuaError)error inBuffer:(NSString*)bufferName inDependentProject:(NSString*)projectName forProject:(NSString*)projectPath;

- (void) shouldClearErrorForBuffer:(NSString*)bufferName inProject:(NSString*)projectPath;

- (void) shouldClearErrorForBuffer:(NSString*)bufferName inDependentProject:(NSString*)projectName forProject:(NSString*)projectPath;

- (void) runtimeErrorOccurred:(nullable NSString*)error;

@end

@interface CodeaScriptExecute : NSObject

@property(nullable, nonatomic, weak) id<ScriptValidateErrorDelegate> errorDelegate;

- (id) initWithCodeaContext:(id)context;

- (BOOL) validateProject:(Project*)project;

- (CodeaLuaState*) setupCodeaEnvironment;

- (BOOL) runProject:(Project*)project;

- (void) addRequiresPath:(NSString*)path;

@end

NS_ASSUME_NONNULL_END
