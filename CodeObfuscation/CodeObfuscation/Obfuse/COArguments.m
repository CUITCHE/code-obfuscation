//
//  COArguments.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/6.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COArguments.h"
#import "global.h"
#import "errorCode.h"
#import "COCacheImage.h"

COArguments *__arguments = nil;

NS_INLINE NSString* arguments_error_helping_string()
{
    NSString *str = [NSString stringWithFormat:@"usage: [-id <path>] [-offset <unsigned integer>] [-root <path>] [-super [--strict=<true|false>]]\n"
                                                "       [-release | -debug] [-db <path>] [-help] [-version]\n"];
    return str;
}

@interface COArguments ()

/// [-id] info.plist的文件目录。默认为当前路径
@property (nonatomic, strong) NSString *infoPlistFilepath;

/// [-offset] 设置混淆名字的偏移量。默认为0。
@property (nonatomic) NSUInteger obfuscationOffset;

/// [-release|-debug] true: 只在release下才会替换混淆命名；false: 任何时候都会启用混淆命名。默认false。
@property (nonatomic) BOOL onlyDebug;

/// [-db] 混淆字符映射的字典存放目录。默认是本程序执行的目录。
@property (nonatomic, strong) NSString *dbFilepath;

/// [-root] 需要混淆的工程路径。默认为当前运行根目录。
@property (nonatomic, strong) NSString *rootpath;

/// [-super] 检查当前类的方法属性是否与它的父类同名，如果同名会以父类为准。[自定义类]。默认false。
@property (nonatomic) BOOL supercheck;
/// [--strict=<true|false>] 在开启-super的情况下，如果继承链中含有iOS Kit中的类，则会对比其方法属性是否父类也存在。如果存在（包含私有方法），则会给出提示信息。默认false。
@property (nonatomic) BOOL strict;

/// [-st=<true|false>] 加强混淆力度。默认true
@property (nonatomic) BOOL st;

@end

@implementation COArguments

+ (instancetype)argumentsWithExecuteArgs:(const char * _Nonnull *)argv argc:(int)argc
{
    COArguments *obj = [COArguments new];
    obj.st = YES;
    __arguments = obj;
    // 分析参数
    NSString *specifier = nil;
    COErrorCode error_code = 0;
    for (int i=1; i<argc; ++i) {
        specifier = [NSString stringWithUTF8String:argv[i]];
        if ([specifier isEqualToString:@"-id"]) {
            if (++i == argc) {
                error_code = COErrorCodeCommandParameters;
                break;
            }
            obj.infoPlistFilepath = [NSString stringWithUTF8String:argv[i]];
            if (obj.infoPlistFilepath.length == 0 || [obj.infoPlistFilepath hasPrefix:@"-"]) {
                error_code = COErrorCodeCommandId;
                break;
            }
        } else if ([specifier isEqualToString:@"-offset"]) {
            if (++i == argc) {
                error_code = COErrorCodeCommandParameters;
                break;
            }
            obj.obfuscationOffset = (NSUInteger)[NSString stringWithUTF8String:argv[i]].longLongValue;
        } else if ([specifier isEqualToString:@"-release"]) {
            obj.onlyDebug = YES;
            if (i + 1 != argc) {
                if (![@(argv[i + 1]) hasPrefix:@"-"]) {
                    error_code = COErrorCodeCommandDebug;
                    break;
                }
            }
        } else if ([specifier isEqualToString:@"-root"]) {
            if (++i == argc) {
                error_code = COErrorCodeCommandParameters;
                break;
            }
            obj.rootpath = [NSString stringWithUTF8String:argv[i]];
            if (obj.rootpath.length == 0 || [obj.rootpath hasPrefix:@"-"]) {
                error_code = COErrorCodeCommandRoot;
                break;
            }
        } else if ([specifier isEqualToString:@"-debug"]) {
            obj.onlyDebug = NO;
            if (i + 1 != argc) {
                if (![@(argv[i + 1]) hasPrefix:@"-"]) {
                    error_code = COErrorCodeCommandDebug;
                    break;
                }
            }
        } else if ([specifier isEqualToString:@"-db"]) {
            if (++i == argc) {
                error_code = COErrorCodeCommandParameters;
                break;
            }
            obj.dbFilepath = [NSString stringWithUTF8String:argv[i]];
            if (obj.dbFilepath.length == 0 || [obj.dbFilepath hasPrefix:@"-"]) {
                error_code = COErrorCodeCommandDb;
                break;
            }
        } else if ([specifier isEqualToString:@"-super"]) {
            obj.supercheck = YES;
            if (i + 1 != argc) {
                specifier = [NSString stringWithUTF8String:argv[i+1]];
                if ([specifier hasPrefix:@"--strict="]) {
                    ++i;
                    NSString *boolVal = [specifier componentsSeparatedByString:@"="].lastObject;
                    obj.strict = boolVal.boolValue;
                }
            }
        } else if ([specifier isEqualToString:@"-help"]) {
            error_code = 0;
            goto exit_;
        } else if ([specifier isEqualToString:@"-version"]) {
            exit_msg(0, "%s", [COCacheImage version].UTF8String);
        } else if ([specifier hasPrefix:@"-st="]) {
            NSString *boolVal = [specifier componentsSeparatedByString:@"="].lastObject;
            obj.st = boolVal.boolValue;
        } else {
            error_code = COErrorCodeCommandUnknown;
            println("Unknown command option: %s\n", specifier.UTF8String);
            break;
        }
    }
    if (error_code != 0) {
    exit_:;
        NSMutableString *str = nil;
        if (error_code == 0) {
            str = [NSMutableString stringWithFormat:@"%@", arguments_error_helping_string()];
        } else {
            str = [NSMutableString stringWithFormat:@"\nError parametes specified.\n%@", arguments_error_helping_string()];
        }
        exit_msg(error_code, "%s", str.UTF8String);
    }
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        _identifier = @"club.we-code.obfuscation";
        _dbFilepath = @".";
        _rootpath = @".";
    }
    return self;
}

- (void)setInfoPlistFilepath:(NSString *)infoPlistFilepath
{
    if (![_infoPlistFilepath isEqualToString:infoPlistFilepath]) {
        _infoPlistFilepath = infoPlistFilepath;
        NSBundle *infoBundle = [NSBundle bundleWithPath:infoPlistFilepath];
        if (!infoBundle) {
            return;
        }
        NSString *path = [infoBundle pathForResource:@"info" ofType:@"plist"];
        if (path) {
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
            _appVersion = dict[(NSString *)kCFBundleVersionKey];
            _identifier = dict[(NSString *)kCFBundleIdentifierKey];
        }
    }
}
@end
