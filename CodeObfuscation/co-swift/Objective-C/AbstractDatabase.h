//
//  AbstractDatabase.h
//  CHE
//
//  Created by hejunqiu on 16/6/22.
//  Copyright © 2016年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FMDatabase;

typedef void *BuildSqlPointer;

@interface AbstractDatabase : NSObject

@property (nonatomic, readonly, getter=isOpened) BOOL opened;
@property (nonatomic, strong, readonly, nullable) FMDatabase *db;
@property (nonatomic, copy, readonly) NSArray<NSString *> *creationSql;
@property (nonatomic, copy, readonly) NSString *databasePath;

@property (nonatomic, assign, readonly) BuildSqlPointer sqlBuilder;

- (instancetype)initWithDatabaseFilePath:(NSString *)filePath;
- (instancetype)init NS_UNAVAILABLE;

/**
 * @author hejunqiu, 16-08-29 15:08:15
 *
 * Must be overrided in subclass.
 *
 */
- (void)constructorSql;
@end

#define GetSqlBuilder() (*((BuildSql *)(self.sqlBuilder)))

#define SqlBuildTail(lineOffset) [=](){ NSString* _ = bs_set_cache(GetSqlBuilder(), lineOffset);\
                    GetSqlBuilder().reset();\
                    return _;}()

#define __getCacheForThisLine() bs_get_cache(GetSqlBuilder())
#define __setCacheForThisLineWithOffset(lineOffset) SqlBuildTail(lineOffset)

NS_ASSUME_NONNULL_END
