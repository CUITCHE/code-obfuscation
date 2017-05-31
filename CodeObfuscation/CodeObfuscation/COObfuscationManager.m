//
//  COObfuscationManager.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/31.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COObfuscationManager.h"
#import "COFileAnalysis.h"
#import "global.h"
#import "errorCode.h"

NSString *const __targetPathExtesion__ = @"coh";

@interface COObfuscationManager ()

@property (nonatomic, strong) NSFileManager *fm;
@property (nonatomic) NSUInteger obfuscationFilesCount;
@property (nonatomic) NSUInteger rate;

@property (nonatomic, strong) NSMutableArray<COFileAnalysis *> *analysisProducts;

@end

@implementation COObfuscationManager

- (instancetype)init
{
    if (self = [super init]) {
        _fm = [NSFileManager defaultManager];
        _analysisProducts = [NSMutableArray arrayWithCapacity:32];
    }
    return self;
}

- (void)goWithRootPath:(NSString *)rootpath
{
    NSString *absolutePath = [[NSBundle bundleWithPath:rootpath] bundlePath];
    BOOL isDir = NO;
    BOOL exist = [_fm fileExistsAtPath:absolutePath isDirectory:&isDir];
    if (!exist) {
        exit_msg(COErrorCodeFilePathIsNotExist, "root path:%s is not exist!", absolutePath.UTF8String);
    }
    if (!isDir) {
        exit_msg(COErrorCodeFileTypeError, "root path:%s is not a directory!", absolutePath.UTF8String);
    }

    // 路径遍历开始
    [self runWithPath:absolutePath];
}

- (void)runWithPath:(NSString *)path
{
    NSError *error = nil;
    NSArray<NSString *> *dirArray = [_fm contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        exit_msg(COErrorCodeOther, "%s", error.localizedDescription.UTF8String);
    }
    NSString *subPath = nil;
    NSArray<NSString *> *obfuscationFiles = [NSBundle pathsForResourcesOfType:__targetPathExtesion__ inDirectory:path];
    if (obfuscationFiles.count) {
        self.obfuscationFilesCount += obfuscationFiles.count;
        static NSString *lastFormatString = nil;
        static const char *status = "/|\\";
        lastFormatString = [NSString stringWithFormat:@"%@ obfuscation files.[%c]",
                            @(self.obfuscationFilesCount),
                            status[_rate % 4]];
        NSString *printString = [NSString stringWithFormat:@"Found %@", lastFormatString];
        fprintf(stderr, "%s\r", printString.UTF8String);
    }

    for (NSString *str in dirArray) {
        subPath = [path stringByAppendingPathComponent:str];
        BOOL isSubDir = NO;
        [_fm fileExistsAtPath:subPath isDirectory:&isSubDir];
        if (isSubDir) {
            [self runWithPath:subPath];
        }
    }
//    println("\nAnalysis obfuscation files...");

    for (NSString *obfus in obfuscationFiles) {
        [self analysisObfuscationWithPath:path filename:obfus.lastPathComponent];
    }
}

- (void)analysisObfuscationWithPath:(NSString *)path filename:(NSString *)filename
{
    NSBundle *bd = [NSBundle bundleWithPath:path];
    NSString *identifier = [filename stringByDeletingPathExtension];
    NSMutableArray<NSString *> *paths = [NSMutableArray arrayWithCapacity:3];
    // 尝试读取.h文件
    NSString *filepath = [bd pathForResource:identifier ofType:@"h"];
    if (filepath) {
        [paths addObject:filepath];
    }
    // 尝试读取.m文件
    filepath = [bd pathForResource:identifier ofType:@"m"];
    if (filepath) {
        [paths addObject:filepath];
    }
    // 尝试读取.mm文件
    filepath = [bd pathForResource:identifier ofType:@"mm"];
    if (filepath) {
        [paths addObject:filepath];
    }
    COFileAnalysis *obj = [[COFileAnalysis alloc] initWithFilepaths:paths];
    [obj start];

    [self.analysisProducts addObject:obj];
}

@end
