//
//  COSelectorPart.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COSelectorPart.h"

@interface COSelectorPart () <NSSecureCoding>

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
    COSelectorPart *obj = [COSelectorPart selectorWithName:name];
    obj.location = location;
    return obj;
}

+ (instancetype)selectorWithName:(NSString *)name
{
    COSelectorPart *obj = [COSelectorPart new];
    obj.name = name;
    return obj;
}

- (void)setSuper:(COMethod *)superMethod
{
    self.super = superMethod;
}

- (BOOL)isEqual:(COSelectorPart *)object
{
    return [object.name isEqualToString:_name];
}

#pragma mark - Coding
+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"n"];
    [aCoder encodeObject:_super forKey:@"s"];
    [aCoder encodeBytes:&_location length:sizeof(_location)];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self == [super init]) {
        _name  = [aDecoder decodeObjectForKey:@"n"];
        _super = [aDecoder decodeObjectForKey:@"s"];
        NSUInteger length = 0;
        void *buf = [aDecoder decodeBytesWithReturnedLength:&length];
        if (length == sizeof(_location) && buf) {
            _location = *(NSRange *)buf;
        } else {
            printf("decode error at Selector Part.\n");
        }
    }
    return self;
}

@end
