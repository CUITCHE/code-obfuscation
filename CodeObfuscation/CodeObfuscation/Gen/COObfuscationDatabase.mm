//
//  COObfuscationDatabase.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/1.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COObfuscationDatabase.h"
#import "BuildSql.h"
#import "FMDB.h"
#import "global.h"
#import <tuple>

using namespace std;

NSString *const kFieldReal  = @"real";
NSString *const kFieldFake  = @"fake";
NSString *const kFieldLocal = @"location";
NSString *const kFieldType  = @"type";

@interface COObfuscationDatabase ()

@property (nonatomic, strong) NSString *bundleIdentifier;
@property (nonatomic, strong) NSString *appVersion;

@end

@implementation COObfuscationDatabase

- (instancetype)initWithDatabaseFilePath:(NSString *)filePath
                        bundleIdentifier:(NSString *)bundleIdentifier
                              appVersion:(NSString *)appVersion
{
    _bundleIdentifier = bundleIdentifier;
    _appVersion = appVersion;
    NSString *databaseName = [NSString stringWithFormat:@"%@-%@.db", bundleIdentifier, appVersion];
    filePath = [filePath stringByAppendingPathComponent:databaseName];
    if (self = [super initWithDatabaseFilePath:filePath]) {
        ;
    }
    return self;
}

- (instancetype)initWithDatabaseFilePath:(NSString *)filePath
{
    return [self initWithDatabaseFilePath:filePath
                         bundleIdentifier:@"club.we-code.obfuscation"
                               appVersion:@([[NSDate date] timeIntervalSince1970]).stringValue];
}

NS_INLINE NSString *typeToString(COObfuscationType type)
{
    static NSString* str[4] = {@"class", @"category", @"property", @"method"};
    return str[type];
}

#pragma mark - Interface
- (void)insertObfuscationWithFilename:(NSString *)filename real:(NSString *)real fake:(NSString *)fake location:(NSString *)location type:(COObfuscationType)type
{
    if ([self _createObfuscationFileTableWithName:filename]) {
        [self _insertToTable:filename withObfuscationInfo:{real, fake, location} type:typeToString(type)];
    }
}

#pragma mark - Action
- (BOOL)_createObfuscationFileTableWithName:(NSString *)tableName
{
    NSString *sql = __getCacheForThisLine();
    if (!sql) {
        GetSqlBuilder().create(@"?").
        column(kFieldReal, SqlTypeText).nonull().
        column(kFieldFake, SqlTypeVarchar, bs_max(4096)).nonull().
        column(kFieldLocal, SqlTypeText).nonull().
        column(kFieldType, SqlTypeText).nonull().end();
        sql = __setCacheForThisLineWithOffset(-7);
    }
    BOOL suc = [self.db executeUpdate:sql, tableName];
    if (!suc) {
        println("%s", self.db.lastErrorMessage.UTF8String);
    }
    return suc;
}

- (BOOL)_insertToTable:(NSString *)tableName withObfuscationInfo:(const tuple<NSString*, NSString*, NSString*> &)argument type:(NSString *)type
{
    NSString *sql = __getCacheForThisLine();
    if (!sql) {
        GetSqlBuilder().insertInto(@"?").field(kFieldReal, kFieldFake, kFieldLocal, kFieldType).values();
        sql = __setCacheForThisLineWithOffset(-3);
    }
    BOOL suc = [self.db executeUpdate:sql, tableName, get<0>(argument), get<1>(argument), get<2>(argument)?:[NSNull null], type];
    if (!suc) {
        println("%s", self.db.lastErrorMessage.UTF8String);
    }
    return suc;
}

#pragma mark - override
- (void)constructorSql
{
}
@end
