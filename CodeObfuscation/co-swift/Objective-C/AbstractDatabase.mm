//
//  AbstractDatabase.m
//  CHE
//
//  Created by hejunqiu on 16/6/22.
//  Copyright © 2016年 CHE. All rights reserved.
//

#import "AbstractDatabase.h"
#import "FMDatabase.h"
#import "BuildSql.h"

BOOL createMultiLevelDirectory(NSFileManager *m, NSString *directory)
{
    BOOL suc = YES;
    if (![m fileExistsAtPath:directory]) {
        suc = [m createDirectoryAtPath:directory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
    }
    return suc;
}

@interface AbstractDatabase ()
{
    FMDatabase *_db;
    BOOL _opened;
    BuildSql _sqlBuilder;
}

@property (nonatomic, copy) NSArray<NSString *> *creationSql;
@property (nonatomic, copy) NSString *databasePath;

@end

@implementation AbstractDatabase

- (instancetype)initWithDatabaseFilePath:(NSString *)filePath
{
    NSAssert(filePath.length, @"filePath is illegal!");
    if (self = [super init]) {
        do {
            if (_opened) {
                break;
            }
#ifdef DEBUG
            NSLog(@"db path:%@", filePath);
#endif
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:filePath]) {
                _opened = [fileManager createDirectoryAtPath:filePath.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
                _opened = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
            } else {
                _opened = YES;
            }
            if (!_opened) {
                break;
            }
            _db = [FMDatabase databaseWithPath:filePath];
            if (_db == nil) {
                _opened = NO;
                break;
            }
            _databasePath = filePath.copy;
            _opened = NO;
            // open
            if (![_db open]) {
                NSLog(@"%@", _db.lastErrorMessage);
                break;
            }
            // create tables
            [self constructorSql];
            NSDictionary<NSString *, NSString *> *sqls = GetSqlBuilder().caches();
            _opened = YES;
            [sqls enumerateKeysAndObjectsUsingBlock:^(__unused NSString *key, NSString *obj, BOOL *stop) {
                if (![_db executeUpdate:obj]) {
                    [_db close];
                    _opened = NO;
                    *stop = YES;
                }
            }];
        } while (0);
        NSAssert(_opened, @"Database initial is failed!");
    }
    return self;
}

- (void)dealloc
{
    [self unload];
}

- (void)unload
{
    if (_opened) {
        [_db close];
        _db = nil;
        _opened = NO;
    }
}

#pragma mark - property
- (BOOL)isOpened
{
    return _opened;
}

- (FMDatabase *)db
{
    return _db;
}

- (BuildSqlPointer)sqlBuilder
{
    return &_sqlBuilder;
}

#pragma mark - override
- (void)constructorSql {}
@end
