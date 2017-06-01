//
//  COFileAnalysis.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COFileAnalysis.h"
#import "COClass.h"
#import "COProperty.h"
#import "COMethod.h"
#import "global.h"

NSString *const scanTagString = @"CO_CONFUSION_";
NSString *const __method__ = @"METHOD";
NSString *const __property__ = @"PROPERTY";

@interface COFileAnalysis ()

@property (nonatomic, strong) NSArray<NSString *> *filepaths;
@property (nonatomic, strong) NSMutableDictionary<NSString *, COClass *> *clazzs;

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
    scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSMutableArray<NSString *> *scannedStrings = [NSMutableArray array];
    NSRange scannedRange;
    while ([scanner scanUpToString:@"@interface" intoString:nil]) {
        scannedRange.location = scanner.scanLocation;
        if (![scanner scanUpToString:@"CO_CONFUSION_CLASS" intoString:nil]) {
            continue;
        }
        [scanner scanString:@"CO_CONFUSION_CLASS" intoString:nil];

        NSString *className = nil;
        if ([scanner scanUpToString:@":" intoString:&className]) { // 类首次声明
            [scanner scanString:@":" intoString:nil];
            NSString *superName = nil;
            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&superName]) {
                ;
            } else {
                @throw [NSException exceptionWithName:NSGenericException reason:@"Code exists error" userInfo:nil];
            }
            className = [className stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            COClass *clazz = [COClass classWithName:className supername:superName];
            NSUInteger location_start = scanner.scanLocation;
            [scanner scanUpToString:@"@end" intoString:nil];
            NSString *classDeclaredString = [classString substringWithRange:NSMakeRange(location_start, scanner.scanLocation - location_start)];
            [self analysisFileWithString:classDeclaredString intoClassObject:clazz methodFlag:@";"];
            [_clazzs setObject:clazz forKey:className];

            [scanner scanString:@"@end" intoString:nil];
            scannedRange.length = scanner.scanLocation - scannedRange.location;
            [scannedStrings addObject:[classString substringWithRange:scannedRange]];
        }
    }

    NSMutableString *restString = classString.mutableCopy;
    for (NSString *str in scannedStrings) {
        [restString replaceOccurrencesOfString:str withString:@"" options:0 range:NSMakeRange(0, restString.length)];
    }
    scanner = [NSScanner scannerWithString:restString];

    // 扫描类别和扩展
    while ([scanner scanUpToString:@"@interface" intoString:nil] && !scanner.atEnd) {
        scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        [scanner scanString:@"@interface" intoString:nil];
        NSString *classname = nil;
        if ([scanner scanUpToString:@"(" intoString:&classname]) {
            if (![scanner scanUpToString:@"CO_CONFUSION_CATEGORY" intoString:nil]) {
                continue;
            }
            [scanner scanString:@"CO_CONFUSION_CATEGORY" intoString:nil];
            classname = [classname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *category = nil;
            COClass *clazz = nil;
            if ([scanner scanUpToString:@")" intoString:&category]) {
                if (category.length == 0) { // 这是扩展。扩展必须从已有的分析的字典里取；否则报错
                    clazz = self.clazzs[classname];
                    if (clazz) {
                        exit_msg(-1, "类扩展(%s): 还没有相应的类", classname.UTF8String);
                    }
                } else { // 这是类别。类别可以自建分析内容
                    clazz = self.clazzs[category];
                    if (!clazz) {
                        clazz = [COClass classWithName:category supername:nil];
                        [_clazzs setObject:clazz forKey:category];
                    }
                }
            }
            if (clazz) {
                NSUInteger location_start = scanner.scanLocation;
                [scanner scanUpToString:@"@end" intoString:nil];
                NSString *classDeclaredString = [restString substringWithRange:NSMakeRange(location_start, scanner.scanLocation - location_start)];
                [self analysisFileWithString:classDeclaredString intoClassObject:clazz methodFlag:@";"];
                [scanner scanString:@"@end" intoString:nil];
            }
        }
        scanner.charactersToBeSkipped = nil;
    }

    // implementation 分析
    scanner = [NSScanner scannerWithString:classString];
    NSMutableCharacterSet *implementationFlag = [NSMutableCharacterSet characterSetWithCharactersInString:@"-+@(\n "];
//    [implementationFlag formIntersectionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    while ([scanner scanUpToString:@"@implementation" intoString:nil] && !scanner.atEnd) {
        [scanner scanString:@"@implementation" intoString:nil];
        NSString *classname = nil;
        if (![scanner scanUpToCharactersFromSet:implementationFlag intoString:&classname]) {
            continue;
        }
        NSString *category = nil;
        NSRange categoryRange = NSMakeRange(NSNotFound, 0);
        for (NSUInteger i=scanner.scanLocation; i<classString.length; ++i) {
            unichar ch = [classString characterAtIndex:i];
            if (ch == ' ' || ch == '\n') {
                continue;
            }
            if (ch == '(') {
                categoryRange.location = i+1;
            } else if (ch == ')') {
                categoryRange.length = i - categoryRange.location;
                category = [classString substringWithRange:categoryRange];
                category = [category stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                break;
            } else {
                if (categoryRange.location == NSNotFound) {
                    break;
                }
            }
        }
        COClass *clazz = self.clazzs[category ?: classname];
        if (!clazz) {
            exit_msg(-1, "code content error");
        }
        NSUInteger location_start = scanner.scanLocation;
        [scanner scanUpToString:@"@end" intoString:nil];
        NSString *classDeclaredString = [restString substringWithRange:NSMakeRange(location_start, scanner.scanLocation - location_start)];
        [self analysisFileWithString:classDeclaredString intoClassObject:clazz methodFlag:@"{"];
        [scanner scanString:@"@end" intoString:nil];
    }
}

/* 该方法传入的是整个文件(.h, .m, .mm)的内容
 * 属性混淆实例：@property (nonatomic, strong) NSString * CO_CONFUSION_PROPERTY prop1;
 * 方法混淆实例：
 * CO_CONFUSION_METHOD
 * - (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2;
 */
- (void)analysisFileWithString:(NSString *)fileString intoClassObject:(COClass *)clazz methodFlag:(NSString *)methodFlag
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
                [clazz addProperty:[COProperty propertyWithName:property
                                                               location:NSMakeRange(scanner.scanLocation - property.length, property.length)]];
            }
        } else if ([string isEqualToString:__method__]) {
            NSString *method = nil;
            if ([scanner scanUpToString:methodFlag intoString:&method]) {
                [method stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                [clazz addMethod:[COMethod methodWithName:method
                                                         location:NSMakeRange(scanner.scanLocation - method.length, method.length)]];
                [self analysisMethodWithString:method intoMethodObject:clazz.methods.lastObject];
            }
        }
    }
}

// example: - (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2 :(NSString *)arg3
- (void)analysisMethodWithString:(NSString *)methodString intoMethodObject:(COMethod *)method
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
    [method addSelector:[COSelectorPart selectorWithName:selector
                                                        location:NSMakeRange(scanner.scanLocation - selector.length, selector.length)]];

    // 找余下的selector
    while ([scanner scanUpToString:@")" intoString:nil]) {
        [scanner scanString:@")" intoString:nil];
        scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
        if ([scanner scanUpToString:@":" intoString:&selector]) {
            [method addSelector:[COSelectorPart selectorWithName:selector
                                                                location:NSMakeRange(scanner.scanLocation - selector.length, selector.length)]];
        }
        scanner.charactersToBeSkipped = nil;
    }
}

@end
