//
//  CODescribeSelectorPart.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "CODescribeSelectorPart.h"

@interface CODescribeSelectorPart ()

@property (nonatomic, strong) CODescribeMethod *super;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) NSRange location;

@end

@implementation CODescribeSelectorPart

+ (instancetype)selectorWithName:(NSString *)name location:(NSRange)location
{
    CODescribeSelectorPart *obj = [CODescribeSelectorPart new];
    obj.name = name;
    obj.location = location;
    return obj;
}

- (void)setSuper:(CODescribeMethod *)superMethod
{
    self.super = superMethod;
}

@end
