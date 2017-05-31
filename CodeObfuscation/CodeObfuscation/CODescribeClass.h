//
//  CODescribeFile.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CODescribeProperty;
@class CODescribeMethod;

@interface CODescribeClass : NSObject

@property (nonatomic, strong, readonly) NSString *classname;
@property (nonatomic, strong, readonly) NSString *supername;
@property (nonatomic, strong, readonly) NSArray<CODescribeProperty *> *properties;
@property (nonatomic, strong, readonly) NSArray<CODescribeMethod *> *methods;

@property (nonatomic, strong) NSString *fullpath;

+ (instancetype)classWithName:(NSString *)classname supername:(NSString *)supername;

- (void)addProperty:(CODescribeProperty *)property;
- (void)addMethod:(CODescribeMethod *)method;

@end
