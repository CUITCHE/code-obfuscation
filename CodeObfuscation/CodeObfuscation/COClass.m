//
//  COFile.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COClass.h"
#import "COMethod.h"
#import "COProperty.h"

@interface COClass ()

@property (nonatomic, strong) NSString *classname;
@property (nonatomic, strong) NSString *supername;
@property (nonatomic, strong) NSMutableArray<COProperty *> *properties;
@property (nonatomic, strong) NSMutableArray<COMethod *> *methods;

@end

@implementation COClass

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
    COClass *obj = [COClass new];
    obj.classname = classname;
    obj.supername = supername;
    return obj;
}

- (void)addProperty:(COProperty *)property
{
    NSParameterAssert(property);
    [_properties addObject:property];
}

- (void)addMethod:(COMethod *)method
{
    NSParameterAssert(method);
    [_methods addObject:method];
}

@end
