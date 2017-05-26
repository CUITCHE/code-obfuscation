//
//  COFileAnalysis.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COFileAnalysis.h"
#import "DescribeClass.h"
#include <map>

using namespace coob;
using namespace std;

NSString *const scanTagString = @"CO_CONFUSION_";
NSString *const __method__ = @"METHOD";
NSString *const __property__ = @"PROPERTY";

@interface COFileAnalysis ()

@property (nonatomic, strong) NSArray<NSString *> *filepaths;
@property (nonatomic) map<NSString *, DescribeClass> classes;

@end

@implementation COFileAnalysis

- (instancetype)initWithFilepaths:(NSArray<NSString *> *)filepaths
{
    if (self = [super init]) {
        self.filepaths = filepaths.copy;
    }
    return self;
}

- (void)start
{
    vector<DescribeClass> classes;
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
    while ([scanner scanUpToString:@"@interface" intoString:nil]) {
        [scanner scanString:@"interface" intoString:nil];
        scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *className = nil;
        if ([scanner scanUpToString:@":" intoString:&className]) {
            DescribeClass clazz(filePath);
            clazz.className = className;
            NSString *superName = nil;
            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&superName]) {
                clazz.superName = superName;
            } else {
                @throw [NSException exceptionWithName:NSGenericException reason:@"Code exists error" userInfo:nil];
            }
            NSUInteger location_start = scanner.scanLocation;
            [scanner scanUpToString:@"@end" intoString:nil];
            NSString *classDeclaredString = [classString substringWithRange:NSMakeRange(location_start, scanner.scanLocation - location_start)];
            [self analysisFileWithString:classDeclaredString intoClassObject:clazz];
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
- (void)analysisFileWithString:(NSString *)fileString intoClassObject:(DescribeClass &)classObject
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
                classObject.declProperties->emplace_back(property,
                                                  NSMakeRange(scanner.scanLocation - property.length, property.length));
            }
        } else if ([string isEqualToString:__method__]) {
            NSString *method = nil;
            if ([scanner scanUpToString:@";" intoString:&method]) {
                [method stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                classObject.declMethods->emplace_back(method,
                                               NSMakeRange(scanner.scanLocation - method.length, method.length));
                [self analysisMethodWithString:method intoMethodObject:classObject.declMethods->back()];
            }
        }
    }
}

// example: - (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2 :(NSString *)arg3
- (void)analysisMethodWithString:(NSString *)methodString intoMethodObject:(DescribeMethod &)method
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
    auto &selectors = *method.selectors;
    selectors.emplace_back(selector, NSMakeRange(scanner.scanLocation - selector.length, selector.length));

    // 找余下的selector
    while ([scanner scanUpToString:@")" intoString:nil]) {
        [scanner scanString:@")" intoString:nil];
        scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
        if ([scanner scanUpToString:@":" intoString:&selector]) {
            selectors.emplace_back(selector, NSMakeRange(scanner.scanLocation - selector.length, selector.length));
        }
        scanner.charactersToBeSkipped = nil;
    }
    NSLog(@".");
}

@end
