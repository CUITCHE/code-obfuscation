//
//  COFile.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class COProperty;
@class COMethod;

@interface COClass : NSObject

@property (nonatomic, strong, readonly) NSString *classname;
@property (nonatomic, strong, readonly) NSString *supername;
@property (nonatomic, strong, readonly) NSArray<COProperty *> *properties;
@property (nonatomic, strong, readonly) NSArray<COMethod *> *methods;

@property (nonatomic, strong) NSString *fullpath;

+ (instancetype)classWithName:(NSString *)classname supername:(NSString *)supername;

- (void)addProperty:(COProperty *)property;
- (void)addMethod:(COMethod *)method;

@end
