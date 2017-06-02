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
#import "_COStringContainer.h"

@interface COClass ()

@property (nonatomic, strong) NSString *classname;
@property (nonatomic, strong) NSMutableArray<COProperty *> *properties;
@property (nonatomic, strong) NSMutableArray<COMethod *> *methods;

@end

@implementation COClass

- (NSString *)description
{
    _COStringContainer *classInfo = ({
        NSString *info = nil;
        if (_categoryname) {
            info = [NSString stringWithFormat:@"%@ (%@)", _classname, _categoryname];
        } else {
            info = [NSString stringWithFormat:@"%@: %@", _classname, _supername];
        }
        [_COStringContainer stringContainer:info];
    });

    _COStringContainer *propertyInfo = ({
        NSString *info = nil;
        if (_properties.count == 0) {
            info = @"()";
        } else {
            info = [NSString stringWithFormat:@"(@%@)", [_properties componentsJoinedByString:@",@"]];
        }
        [_COStringContainer stringContainer:info];
    });

    _COStringContainer *methodInfo = ({
        NSString *info = [_methods componentsJoinedByString:@","];
        [_COStringContainer stringContainer:info];
    });

    NSString *str = [NSString stringWithFormat:@"{\nclass = %@;\nproperty = %@;\nmethod = %@;\n}",
                     classInfo, propertyInfo, methodInfo];
    return str;
}

- (NSString *)debugDescription
{
    return self.description;
}

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
