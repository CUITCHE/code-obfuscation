//
//  CODescribeMethod.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CODescribeSelectorPart.h"

@interface CODescribeMethod : NSObject

@property (nonatomic, strong, readonly) NSString *method;
@property (nonatomic, readonly) NSRange location;
@property (nonatomic, strong, readonly) NSArray<CODescribeSelectorPart *> *selectors;

+ (instancetype)methodWithName:(NSString *)methodName location:(NSRange)location;
- (void)addSelector:(CODescribeSelectorPart *)selector;

- (BOOL)equalSelectorsTo:(CODescribeMethod *)other;

@end
