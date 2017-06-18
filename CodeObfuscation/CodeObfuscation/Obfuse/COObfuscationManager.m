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
#import "COObfuscationDatabase.h"
#import "COCacheImage.h"

#import "COProperty.h"
#import "COMethod.h"
#import "COClass.h"
#import "COArguments.h"
#import <objc/runtime.h>

NSString *const __targetPathExtesion__ = @"coh";
static NSMutableDictionary<NSString *, NSString *> *classRelationshipReg = nil;

NSMutableDictionary<NSString *, COClass *> *g_clazzs = nil;

void registerClassRelationship(NSString *classname, NSString *super, COClass *clazz)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classRelationshipReg = [NSMutableDictionary dictionary];
        g_clazzs             = [NSMutableDictionary dictionary];
    });
    [classRelationshipReg setObject:super forKey:classname];
    if (clazz.categoryname == nil) {
        [g_clazzs setObject:clazz forKey:classname];
    }
}

@interface COObfuscationManager ()
{
    NSUInteger _fakeOffset;
    NSUInteger _fakeSource;
}

@property (nonatomic, strong) NSFileManager *fm;
@property (nonatomic) NSUInteger obfuscationFilesCount;
@property (nonatomic) NSUInteger rate;

@property (nonatomic, strong) NSMutableArray<COFileAnalysis *> *analysisProducts;
@property (nonatomic, strong) NSString *dbSavePath;

@property (nonatomic, strong) COCacheImage *imageCache;

@end

@implementation COObfuscationManager

- (instancetype)init
{
    if (self = [super init]) {
        _fm = [NSFileManager defaultManager];
        _analysisProducts = [NSMutableArray arrayWithCapacity:32];
        _imageCache = [[COCacheImage alloc] init];
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
    _dbSavePath = absolutePath;
    // 路径遍历开始
    [self _runWithPath:absolutePath];
    [self _saveToDatabase];
}

- (void)_runWithPath:(NSString *)path
{
    NSError *error = nil;
    NSArray<NSString *> *dirArray = [_fm contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        exit_msg(COErrorCodeOther, "%s", error.localizedDescription.UTF8String);
    }

    NSArray<NSString *> *obfuscationFiles = [NSBundle pathsForResourcesOfType:__targetPathExtesion__ inDirectory:path];
    if (obfuscationFiles.count) {
        self.obfuscationFilesCount += obfuscationFiles.count;
        static NSString *lastFormatString = nil;
        static const char *status = "/|\\";
        lastFormatString = [NSString stringWithFormat:@"%@ obfuscation(.coh) files.[%c]",
                            @(self.obfuscationFilesCount),
                            status[_rate % 4]];
        NSString *printString = [NSString stringWithFormat:@"Found %@", lastFormatString];
        fprintf(stderr, "%s\r", printString.UTF8String);
    }

    NSString *subPath = nil;
    for (NSString *str in dirArray) {
        subPath = [path stringByAppendingPathComponent:str];
        BOOL isSubDir = NO;
        [_fm fileExistsAtPath:subPath isDirectory:&isSubDir];
        if (isSubDir) {
            [self _runWithPath:subPath];
        }
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        println("\nAnalysis obfuscation files...");
    });

    for (NSString *obfus in obfuscationFiles) {
        [self _analysisObfuscationWithPath:path filename:obfus.lastPathComponent];
    }
}

- (void)_analysisObfuscationWithPath:(NSString *)path filename:(NSString *)filename
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
    COFileAnalysis *obj = [[COFileAnalysis alloc] initWithFilepaths:paths
                                                    writtenFilepath:[path stringByAppendingPathComponent:filename]];
    [obj start];

    [self.analysisProducts addObject:obj];
}

- (void)_saveToDatabase
{
    // 整理class
    [self _formatClass];
    if (!_fakeOffset) {
        _fakeOffset = arc4random();
    }
    _fakeSource = _fakeOffset;
    // Fake start
    for (COFileAnalysis *file in self.analysisProducts) {
        [self _fakeWithFile:file];
    }

    [self _distinct];

    [self _superCheck];

    COObfuscationDatabase *db = [[COObfuscationDatabase alloc] initWithDatabaseFilePath:_dbSavePath
                                                                       bundleIdentifier:__arguments.identifier
                                                                             appVersion:__arguments.appVersion];
    for (COFileAnalysis *file in self.analysisProducts) {
        [file.clazzs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, COClass * _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *filename = file.cohFilepath.lastPathComponent;
            filename = [filename stringByReplacingOccurrencesOfString:@"." withString:@"_"];
            [db insertObfuscationWithFilename:filename
                                         real:key
                                         fake:obj.fakename
                                     location:@""
                                         type:!!obj.categoryname];
            for (COProperty *prop in obj.properties) {
                [db insertObfuscationWithFilename:filename
                                             real:prop.name
                                             fake:prop.fakename
                                         location:@""
                                             type:COObfuscationTypeProperty];
            }
            for (COMethod *method in obj.methods) {
                for (COSelectorPart *sel in method.selectors) {
                    [db insertObfuscationWithFilename:filename
                                                 real:sel.name
                                                 fake:sel.fakename
                                             location:@""
                                                 type:COObfuscationTypeMethod];
                }
            }
        }];
        [file write];
    }
}

- (void)_distinct
{
    // 为避免real-name存在重复的情况，对全局real-name去重
    NSMutableDictionary<NSString *, id> *relationship = [NSMutableDictionary dictionary];
    for (COFileAnalysis *file in self.analysisProducts) {
        [file.clazzs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, COClass * _Nonnull obj, BOOL * _Nonnull stop) {
            id val = nil;
            for (COProperty *prop in obj.properties) {
                val = relationship[prop.name];
                if (val) {
                    prop.fakename = [val fakename];
                } else {
                    relationship[prop.name] = prop;
                }
            }
            for (COMethod *method in obj.methods) {
                for (COSelectorPart *sel in method.selectors) {
                    val = relationship[sel.name];
                    if (val) {
                        sel.fakename = [val fakename];
                    } else {
                        relationship[sel.name] = sel;
                    }
                }
            }
        }];
    }
}

- (void)_superCheck
{
    if (__arguments.supercheck) {
        println("User: check user's class...");
        for (COFileAnalysis *file in self.analysisProducts) {
            [file.clazzs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, COClass * _Nonnull obj, BOOL * _Nonnull stop) {
                if (obj.categoryname) {
                    return;
                }
                COClass *superClass = nil;
                if (obj.categoryname) {
                    superClass = g_clazzs[g_clazzs[obj.classname].supername];
                } else {
                    superClass = g_clazzs[obj.supername];
                }
                if (superClass) {
                    for (COMethod *method in obj.methods) {
                        for (COMethod *superMethod in superClass.methods) {
                            if ([method isEqual:superMethod]) {
                                [method fakeWithAnotherMethod:superMethod];
                                println("\033[47;33m[Warning]: (%s,%s), duplicate method: %s. Fixed the fake name by super's\033[0m",key.UTF8String,
                                        superClass.classname.UTF8String,
                                        method.method.UTF8String);
                            }
                        }
                    }
                }
            }];
        }
        if (__arguments.strict) {
            println("User: check iOS Kits classes. This operation may need more time...");
            for (COFileAnalysis *file in self.analysisProducts) {
                [file.clazzs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, COClass * _Nonnull obj, BOOL * _Nonnull stop) {
                    for (COMethod *user in obj.methods) {
                        if ([self.imageCache searchMethod:user withSupername:obj.supername]) {
                            println("\033[47;33m[Warning]: (%s,%s), You can't OBFUSE the system method: %s\033[0m",key.UTF8String,
                                    obj.supername.UTF8String,
                                    user.method.UTF8String);
                        }
                    }
                }];
            }
        }
    }
}

- (void)_formatClass
{
    for (COFileAnalysis *analysis in self.analysisProducts) {
        [analysis.clazzs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, COClass * _Nonnull obj, BOOL * _Nonnull stop) {
            if (!obj.supername) {
                obj.supername = classRelationshipReg[obj.className];
            }
        }];
    }
}

- (void)_fakeWithFile:(COFileAnalysis *)file
{
    [file.clazzs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, COClass * _Nonnull obj, BOOL * _Nonnull stop) {
        obj.fakename = [self getFakeStringRandomly];
        for (COProperty *prop in obj.properties) {
            prop.fakename = [self getFakeStringRandomly];
        }
        for (COMethod *method in obj.methods) {
            for (COSelectorPart *sel in method.selectors) {
                sel.fakename = [self getFakeStringRandomly];
            }
        }
    }];
}

- (NSString *)getFakeStringRandomly
{
    static const char *fakeCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_";
    static unsigned short index = 0;
    NSString *fake = [NSString stringWithFormat:@"%c%lu%c",
                      fakeCharacters[index++ % 53], ++_fakeSource, fakeCharacters[arc4random() % 53]];
    return fake;
}

@end
