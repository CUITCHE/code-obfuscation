//
//  COSelectorPart.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COSelectorPart.h"

@interface COSelectorPart ()

@property (nonatomic, strong) COMethod *super;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) NSRange location;

@end

@implementation COSelectorPart

- (NSString *)description
{
    NSString *str = [NSString stringWithFormat:@"(%@, %@)", _name, NSStringFromRange(_location)];
    return str;
}

- (NSString *)debugDescription
{
    NSString *str = [NSString stringWithFormat:@"%@ -> %@", self.description, _super];
    return str;
}

+ (instancetype)selectorWithName:(NSString *)name location:(NSRange)location
{
    COSelectorPart *obj = [COSelectorPart new];
    obj.name = name;
    obj.location = location;
    return obj;
}

- (void)setSuper:(COMethod *)superMethod
{
    self.super = superMethod;
}

@end
