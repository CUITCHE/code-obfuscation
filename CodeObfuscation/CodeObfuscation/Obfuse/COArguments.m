//
//  COArguments.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/6.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COArguments.h"
#import "global.h"

COArguments *__arguments = nil;

@implementation COArguments

+ (instancetype)argumentsWithExecuteArgs:(const char * _Nonnull *)argv argc:(int)argc
{
    COArguments *obj = [COArguments new];
    __arguments = obj;
    // 分析参数
    NSString *specifier = nil;
    for (int i=1; i<argc; ++i) {
        specifier = [NSString stringWithUTF8String:argv[i]];
        if ([specifier isEqualToString:@"-id"]) {
            if (++i == argc) {
                exit_msg(-9, "Should be a path argument after id.");
            }
            obj.infoPlistFilepath = [NSString stringWithUTF8String:argv[i]];
        } else if ([specifier isEqualToString:@"-offset"]) {
            if (++i == argc) {
                exit_msg(-9, "Should be a integer argument after offset.");
            }
            obj.obfuscationOffset = (NSUInteger)[NSString stringWithUTF8String:argv[i]].longLongValue;
        } else if ([specifier isEqualToString:@"-release"]) {
            obj.onlyDebug = YES;
        } else if ([specifier isEqualToString:@"-root"]) {
            if (++i == argc) {
                exit_msg(-9, "Should be a path argument after root.");
            }
            obj.rootpath = [NSString stringWithUTF8String:argv[i]];
        } else if ([specifier isEqualToString:@"-debug"]) {
            obj.onlyDebug = NO;
        } else if ([specifier isEqualToString:@"-db"]) {
            if (++i == argc) {
                exit_msg(-9, "Should be a path argument after db.");
            }
            obj.dbFilepath = [NSString stringWithUTF8String:argv[i]];
        }
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
