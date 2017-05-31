//
//  COTemplateFile.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COTemplateFile.h"

@interface COTemplateFile ()

@end

@implementation COTemplateFile
@synthesize prop1;

- (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2
{
    ;
}

- (instancetype)initWithArg1:(CGFloat)arg, ...
{
    return nil;
}

CO_CONFUSION_METHOD
- (void)_private:(NSString *)arg1 method:(float)arg2 scanned:(BOOL)scanned
{
    ;
}

- (void)_private:(NSString *)arg1 untagged:(NSUInteger)arg2 doNotBeScanned:(NSArray *)arg3
{
    ;
}

@end

@implementation COTemplateFile (oxxxxo)

CO_CONFUSION_METHOD
- (void)_pri:(NSString *)arg1 arg2:(NSString *)arg2
{
    ;
}

@end

@implementation NSString (abcde)

CO_CONFUSION_METHOD
- (void)_pri:(NSString *)arg1 arg2:(NSString *)arg2
{
    ;
}

- (void)test:(CGFloat)arg
{
    ;
}

@end
