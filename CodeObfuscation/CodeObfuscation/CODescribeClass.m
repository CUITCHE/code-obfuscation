//
//  CODescribeFile.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "CODescribeClass.h"
#import "CODescribeMethod.h"
#import "CODescribeProperty.h"

@interface CODescribeClass ()

@property (nonatomic, strong) NSString *classname;
@property (nonatomic, strong) NSString *supername;
@property (nonatomic, strong) NSMutableArray<CODescribeProperty *> *properties;
@property (nonatomic, strong) NSMutableArray<CODescribeMethod *> *methods;

@end

@implementation CODescribeClass

- (instancetype)init
{
    if (self = [super init]) {
        _properties = [NSMutableArray array];
        _methods    = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)classWithName:(NSString *)classname supername:(NSString *)supername
{
    CODescribeClass *obj = [CODescribeClass new];
    obj.classname = classname;
    obj.supername = supername;
    return obj;
}

- (void)addProperty:(CODescribeProperty *)property
{
    NSParameterAssert(property);
    [_properties addObject:property];
}

- (void)addMethod:(CODescribeMethod *)method
{
    NSParameterAssert(method);
    [_methods addObject:method];
}

@end
