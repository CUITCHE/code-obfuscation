//
//  COMethod.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COMethod.h"
#import "NSString+COMD5.h"

@interface COMethod ()

@property (nonatomic, strong) NSString *method;
@property (nonatomic) NSRange location;
@property (nonatomic, strong) NSMutableArray<COSelectorPart *> *selectors;

@end

@implementation COMethod

- (instancetype)init
{
    if (self = [super init]) {
        _selectors = [NSMutableArray arrayWithCapacity:3];
    }
    return self;
}

+ (instancetype)methodWithName:(NSString *)methodName location:(NSRange)location
{
    COMethod *obj = [COMethod new];
    obj.method = methodName;
    obj.location = location;
    return obj;
}

- (void)addSelector:(COSelectorPart *)selector
{
    NSParameterAssert(selector);
    [_selectors addObject:selector];
}

- (BOOL)equalSelectorsTo:(COMethod *)other
{
    if (other.selectors.count != _selectors.count) {
        return NO;
    }
    NSEnumerator<COSelectorPart *> *otherMethod = other.selectors.objectEnumerator;
    for (COSelectorPart *sel in _selectors) {
        if (![sel.name isEqualToString:[otherMethod nextObject].name]) {
            return NO;
        }
    }
    return YES;
}

@end
