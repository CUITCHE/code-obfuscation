//
//  CODescribeMethod.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "CODescribeMethod.h"
#import "NSString+COMD5.h"

@interface CODescribeMethod ()

@property (nonatomic, strong) NSString *method;
@property (nonatomic) NSRange location;
@property (nonatomic, strong) NSMutableArray<CODescribeSelectorPart *> *selectors;

@end

@implementation CODescribeMethod

- (instancetype)init
{
    if (self = [super init]) {
        _selectors = [NSMutableArray arrayWithCapacity:3];
    }
    return self;
}

+ (instancetype)methodWithName:(NSString *)methodName location:(NSRange)location
{
    CODescribeMethod *obj = [CODescribeMethod new];
    obj.method = methodName;
    obj.location = location;
    return obj;
}

- (void)addSelector:(CODescribeSelectorPart *)selector
{
    NSParameterAssert(selector);
    [_selectors addObject:selector];
}

- (BOOL)equalSelectorsTo:(CODescribeMethod *)other
{
    if (other.selectors.count != _selectors.count) {
        return NO;
    }
    NSEnumerator<CODescribeSelectorPart *> *otherMethod = other.selectors.objectEnumerator;
    for (CODescribeSelectorPart *sel in _selectors) {
        if (![sel.name isEqualToString:[otherMethod nextObject].name]) {
            return NO;
        }
    }
    return YES;
}

@end
