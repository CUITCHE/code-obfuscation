//
//  COMethod.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COMethod.h"
#import "NSString+COMD5.h"

@interface COMethod () <NSSecureCoding>

@property (nonatomic, strong) NSString *method;
@property (nonatomic) NSRange location;
@property (nonatomic, strong) NSMutableArray<COSelectorPart *> *selectors;

@end

@implementation COMethod

- (NSString *)description
{
    NSMutableArray<NSString *> *elements = [NSMutableArray arrayWithCapacity:_selectors.count];
    for (COSelectorPart *sel in _selectors) {
        [elements addObject:sel.name];
    }
    NSString *str = [NSString stringWithFormat:@"[%@:]", [elements componentsJoinedByString:@":"]];
    return str;
}

- (NSString *)debugDescription
{
    return self.description;
}

- (instancetype)init
{
    if (self = [super init]) {
        _selectors = [NSMutableArray arrayWithCapacity:3];
    }
    return self;
}

+ (instancetype)methodWithName:(NSString *)methodName location:(NSRange)location
{
    COMethod *obj = [COMethod methodWithName:methodName];
    obj.location = location;
    return obj;
}

+ (instancetype)methodWithName:(NSString *)methodName
{
    COMethod *obj = [COMethod new];
    obj.method = methodName;
    return obj;
}

- (void)addSelector:(COSelectorPart *)selector
{
    NSParameterAssert(selector);
    [_selectors addObject:selector];
}

- (BOOL)equalSelectorsTo:(COMethod *)other
{
    return [_selectors isEqualToArray:other.selectors];
}

- (BOOL)isEqual:(COMethod *)object
{
    return [self equalSelectorsTo:object];
}

#pragma mark - Coding
+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_method forKey:@"m"];
    [aCoder encodeObject:_selectors forKey:@"ss"];
    [aCoder encodeBytes:&_location length:sizeof(_location)];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _method    = [aDecoder decodeObjectForKey:@"m"];
        _selectors = [aDecoder decodeObjectForKey:@"ss"];
        NSUInteger length = 0;
        void *buf = [aDecoder decodeBytesWithReturnedLength:&length];
        if (length == sizeof(_location) && buf) {
            _location = *(NSRange *)buf;
        } else {
            printf("decode error at Method.\n");
        }
    }
    return self;
}
@end
