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

COArguments *__arguments = nil;

NS_INLINE NSString* arguments_error_helping_string()
{
    NSString *str = [NSString stringWithFormat:@"usage: [-id <path>] [-offset <unsigned integer>] [-root <path>]\n"
                                                "       [-release | -debug] [-db <path>]"];
    return str;
}

@implementation COArguments

+ (instancetype)argumentsWithExecuteArgs:(const char * _Nonnull *)argv argc:(int)argc
{
    COArguments *obj = [COArguments new];
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
                if ([specifier hasPrefix:@"strict="]) {
                    NSString *boolVal = [specifier componentsSeparatedByString:@"="].lastObject;
                    obj.strict = boolVal.boolValue;
                }
            }
        } else {
            error_code = COErrorCodeCommandUnknown;
            println("Unknown command option: %s\n", specifier.UTF8String);
            break;
        }
    }
    if (error_code != 0) {
        NSMutableString *str = [NSMutableString stringWithFormat:@"\nError parametes specified.\n%@", arguments_error_helping_string()];
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
