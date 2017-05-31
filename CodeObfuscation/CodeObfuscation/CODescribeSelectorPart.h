//
//  CODescribeSelectorPart.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CODescribeMethod;

@interface CODescribeSelectorPart : NSObject

@property (nonatomic, strong, readonly) CODescribeMethod *super;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, readonly) NSRange location;

+ (instancetype)selectorWithName:(NSString *)name location:(NSRange)location;

- (void)setSuper:(CODescribeMethod *)superMethod;
@end
