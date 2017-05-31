//
//  COFileAnalysis.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COFileAnalysis.h"
#import "CODescribeClass.h"
#import "CODescribeProperty.h"
#import "CODescribeMethod.h"

NSString *const scanTagString = @"CO_CONFUSION_";
NSString *const __method__ = @"METHOD";
NSString *const __property__ = @"PROPERTY";

@interface COFileAnalysis ()

@property (nonatomic, strong) NSArray<NSString *> *filepaths;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CODescribeClass *> *clazzs;

@end

@implementation COFileAnalysis

- (instancetype)initWithFilepaths:(NSArray<NSString *> *)filepaths
{
    if (self = [super init]) {
        _filepaths = filepaths;
        _clazzs = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)start
{
    for (NSString *filepath in self.filepaths) {
        NSError *error = nil;
        NSString *fileContent = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"%@", error);
            continue;
        }
        [self analysisClassWithString:fileContent filePath:filepath];
    }
}

- (void)analysisClassWithString:(NSString *)classString filePath:(NSString *)filePath
{
    NSScanner *scanner = [NSScanner scannerWithString:classString];
    while ([scanner scanUpToString:@"CO_CONFUSION_CLASS" intoString:nil]) {
        [scanner scanString:@"CO_CONFUSION_CLASS" intoString:nil];
        scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *className = nil;
        if ([scanner scanUpToString:@":" intoString:&className]) {
            [scanner scanString:@":" intoString:nil];
            NSString *superName = nil;
            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&superName]) {
                ;
            } else {
                @throw [NSException exceptionWithName:NSGenericException reason:@"Code exists error" userInfo:nil];
            }
            CODescribeClass *clazz = [CODescribeClass classWithName:className supername:superName];
            NSUInteger location_start = scanner.scanLocation;
            [scanner scanUpToString:@"@end" intoString:nil];
            NSString *classDeclaredString = [classString substringWithRange:NSMakeRange(location_start, scanner.scanLocation - location_start)];
            [self analysisFileWithString:classDeclaredString intoClassObject:clazz];
            [_clazzs setObject:clazz forKey:className];
        }
        scanner.charactersToBeSkipped = nil;
    }
}

/* 该方法传入的是整个文件(.h, .m, .mm)的内容
 * 属性混淆实例：@property (nonatomic, strong) NSString * CO_CONFUSION_PROPERTY prop1;
 * 方法混淆实例：
 * CO_CONFUSION_METHOD
 * - (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2;
 */
- (void)analysisFileWithString:(NSString *)fileString intoClassObject:(CODescribeClass *)clazz
{
    NSScanner *scanner = [NSScanner scannerWithString:fileString];
    NSString *string = nil;
    while ([scanner scanUpToString:scanTagString intoString:&string]) {
        [scanner scanString:scanTagString intoString:nil];
        // 扫描property或者method
        string = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&string];
        if ([string isEqualToString:__property__]) {
            NSString *property = nil;
            if ([scanner scanUpToString:@";" intoString:&property]) {
                [clazz addProperty:[CODescribeProperty propertyWithName:property
                                                               location:NSMakeRange(scanner.scanLocation - property.length, property.length)]];
            }
        } else if ([string isEqualToString:__method__]) {
            NSString *method = nil;
            if ([scanner scanUpToString:@";" intoString:&method]) {
                [method stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                [clazz addMethod:[CODescribeMethod methodWithName:method
                                                         location:NSMakeRange(scanner.scanLocation - method.length, method.length)]];
                [self analysisMethodWithString:method intoMethodObject:clazz.methods.lastObject];
            }
        }
    }
}

// example: - (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2 :(NSString *)arg3
- (void)analysisMethodWithString:(NSString *)methodString intoMethodObject:(CODescribeMethod *)method
{
    NSScanner *scanner = [NSScanner scannerWithString:methodString];
    // 找到第一个selector
    NSString *selector = nil;
    [scanner scanUpToString:@")" intoString:nil];
    scanner.scanLocation += 1;
    scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    [scanner scanUpToString:@":" intoString:&selector];
    if (selector == nil) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Code exists error." userInfo:nil];
    }
    scanner.charactersToBeSkipped = nil;
    [method addSelector:[CODescribeSelectorPart selectorWithName:selector
                                                        location:NSMakeRange(scanner.scanLocation - selector.length, selector.length)]];

    // 找余下的selector
    while ([scanner scanUpToString:@")" intoString:nil]) {
        [scanner scanString:@")" intoString:nil];
        scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
        if ([scanner scanUpToString:@":" intoString:&selector]) {
            [method addSelector:[CODescribeSelectorPart selectorWithName:selector
                                                                location:NSMakeRange(scanner.scanLocation - selector.length, selector.length)]];
        }
        scanner.charactersToBeSkipped = nil;
    }
}

@end
