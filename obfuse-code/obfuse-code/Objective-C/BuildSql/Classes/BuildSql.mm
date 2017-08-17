//
//  BuildSql.mm
//  buildSQL
//
//  Created by hejunqiu on 16/6/30.
//  Copyright © 2016年 CHE. All rights reserved.
//

#import "BuildSql.h"

struct SqlMakerPrivateData
{
    NSMutableString *sql;
    NSString *placeholder;
    NSMutableDictionary<NSString *, NSString *> *cache_sql;
    SqlType lastTypeOfField;

    uint32_t isFinished  : 1;
    uint32_t inserting   : 1;
    uint32_t updating    : 1;
    uint32_t deleting    : 1;
    uint32_t selecting   : 1;
    uint32_t creating    : 1;
    uint32_t operation   : 1;       // 上一个操作是=,<>,>,<,<=,>=等操作
    uint32_t creatingHasColumn : 1; // 已经添加一列了
    uint32_t betweening  : 1;
    uint32_t selectedArgs: 1;       // 已经在select中插入了筛选列
    uint32_t joining     : 1;       // 正在进行join操作
    uint32_t insertCount : 21;      // 以后这个参数表示的大小可能会变化
#if __LP64__
    uint32_t reserved;
#endif

    SqlMakerPrivateData()
    :sql([NSMutableString stringWithCapacity:40])
    {
        clean();
    }

    void clean() {
        isFinished          = 0;
        insertCount         = 0;
        updating            = 0;
        deleting            = 0;
        selecting           = 0;
        creating            = 0;
        operation           = 0;
        insertCount         = 0;
        creatingHasColumn   = 0;
        betweening          = 0;
        selectedArgs        = 0;
        joining             = 0;
        [sql setString:@""];
    }
};

BuildSql::BuildSql(NSString *placehodler/* = @"?"*/)
:d(new struct SqlMakerPrivateData())
{
    d->placeholder = placehodler.copy;
}

BuildSql::~BuildSql()
{
    delete d;
}

BuildSql& BuildSql::from(NSString *table)
{
    [[d->sql append:@" FROM "] appendString:table];
    d->selectedArgs = 0;
    return *this;
}

BuildSql& BuildSql::from(NSArray<NSString *> *tables)
{
    NSCAssert(tables.count, @"Illegal param tables.count = 0.");
    [d->sql appendString:@" FROM "];
    bool first = YES;
    for (NSString *table in tables) {
        if (first) {
            first = false;
            [d->sql appendString:table];
        } else {
            [d->sql appendFormat:@",%@", table];
        }
    }
    d->selectedArgs = 0;
    return *this;
}

BuildSql& BuildSql::where(NSString *field)
{
    [[d->sql append:@" WHERE "] appendString:field];
    d->selectedArgs = 0;
    return *this;
}

BuildSql& BuildSql::Delete(NSString *table)
{
    do {
        if (d->sql.length) {
            NSCAssert(NO, @"SQL: sql syntax error.");
            break;
        }
        [[d->sql append:@"DELETE FROM "] appendString:table];
    } while (0);
    return *this;
}

BuildSql& BuildSql::update(NSString *table)
{
    do {
        if (d->sql.length) {
            NSCAssert(NO, @"SQL: sql syntax error.");
            break;
        }
        [[[d->sql append:@"UPDATE "] append:table] append:@" SET "];
    } while (0);
    return *this;
}

BuildSql& BuildSql::insertInto(NSString *table)
{
    do {
        if (d->sql.length) {
            NSCAssert(NO, @"SQL: sql syntax error.");
            break;
        }
        [[d->sql append:@"INSERT INTO "] append:table];
        this->scopes();
        d->inserting = 1;
    } while (0);
    return *this;
}

void BuildSql::values()
{
    do {
        if (!d->inserting) {
            d->insertCount = 0;
            break;
        }
        NSCAssert(d->insertCount, @"SQL: no matched number of placeholder");
        this->scopee();
        [[d->sql append:@" VALUES("] append:d->placeholder];
        while (--d->insertCount) {
            [[d->sql append:@","] append:d->placeholder];
        }
        [d->sql append:@")"];
        this->end();
    } while(0);
}

BuildSql& BuildSql::scopes()
{
    [d->sql appendString:@"("];
    return *this;
}

BuildSql& BuildSql::scopee()
{
    [d->sql appendString:@")"];
    return *this;
}

BuildSql& BuildSql::value(id val)
{
    if ([val isKindOfClass:[NSNumber class]]) {
        [d->sql appendString:[val stringValue]];
    } else if ([val isKindOfClass:[NSString class]]) {
        [d->sql appendFormat:@"'%@'", val];
    } else {
        NSCAssert(NO, @"SQL: unsupport type:%@", [val class]);
    }
    return *this;
}

BuildSql& BuildSql::orderBy(NSString *field, Order order/* = ASC*/)
{
    [[d->sql append:@" ORDER BY "] appendString:field];
    if (order == DESC) {
        [d->sql appendString:@" DESC"];
    }
    return *this;
}

BuildSql& BuildSql::create(NSString *table)
{
    do {
        if (d->creating) {
            NSCAssert(NO, @"SQL: sql syntax error. You are already in creat-funcational. And you couldn't use 'creat' again.");
            break;
        }
        [[d->sql append:@"CREATE TABLE IF NOT EXISTS "] appendString:table];
        d->creating = 1;
    } while (0);
    return this->scopes();
}

BuildSql& BuildSql::column(NSString *name, SqlType type, __capacity capacity/* = {0,0}*/)
{
#define __common(type) [words appendFormat:@"%@ %s", name, #type];
#define __case(type) case SqlType##type:\
                        __common(type) \
                        break
#define __caseCapacity(type) case SqlType##type:\
                                __common(type)\
                                [words appendFormat:@"(%u)",bs_whole(capacity)];\
                                break
#define __case2Place(type) case SqlType##type:\
                                __common(type)\
                                [words appendFormat:@"(%u,%u)",capacity.wholeMax,capacity.rightMax];\
                                break
    if (!name.length) {
        return *this;
    }
    NSMutableString *words = [NSMutableString stringWithCapacity:20];
    switch (type) {
        __case(Int);
        __case(TinyInt);
        __case(SmallInt);
        __case(MediumInt);
        __case(BigInt);
        __case(UnsignedBigInt);
        __case(Int2);
        __case(Int8);
        __case(Integer);
        __caseCapacity(Varchar);
        __caseCapacity(NVarchar);
        __caseCapacity(Char);
        __caseCapacity(NChar);
        __case(CLOB);
        __case(Text);
        __case(Double);
        __case(Float);
        __case(Real);
        __case2Place(Decimal);
        __case(Date);
        __case(DateTime);
        __case(Boolean);
        __case2Place(Numeric);
        __case(Blob);
        default:
            return *this;
    }
    if (d->creatingHasColumn) {
        [d->sql appendString:@","];
    } else {
        d->creatingHasColumn = 1;
    }
    [d->sql appendString:words];
    d->lastTypeOfField = type;
    return *this;
}

#pragma mark - final sql
NSString* BuildSql::sql() const
{
    return d->sql.copy;
}

#pragma mark - operation
BuildSql& BuildSql::equalTo(id value)
{
    do {
        if ([value isKindOfClass:[NSNumber class]] || d->joining) {
            [d->sql appendFormat:@"=%@",value];
        } else if ([value isKindOfClass:[NSString class]]) {
            [d->sql appendFormat:@"='%@'",value];
        } else {
            NSCAssert(NO, @"SQL: unsupport type:%@", [value class]);
        }
    } while (0);
    return *this;
}

BuildSql& BuildSql::et()
{
    [d->sql appendFormat:@"=%@", d->placeholder];
    return *this;
}

BuildSql& BuildSql::notEqualTo(id value)
{
    do {
        if ([value isKindOfClass:[NSNumber class]] || d->joining) {
            [d->sql appendFormat:@"<>%@",value];
        } else if ([value isKindOfClass:[NSString class]]) {
            [d->sql appendFormat:@"<>'%@'",value];
        } else {
            NSCAssert(NO, @"SQL: unsupport type:%@", [value class]);
        }
    } while (0);
    return *this;
}

BuildSql& BuildSql::net()
{
    [d->sql appendFormat:@"<>%@", d->placeholder];
    return *this;
}

BuildSql& BuildSql::greaterThan(id value)
{
    do {
        if ([value isKindOfClass:[NSNumber class]] || d->joining) {
            [d->sql appendFormat:@">%@",value];
        } else if ([value isKindOfClass:[NSString class]]) {
            [d->sql appendFormat:@">'%@'",value];
        } else {
            NSCAssert(NO, @"SQL: unsupport type:%@", [value class]);
        }
    } while (0);
    return *this;
}

BuildSql& BuildSql::gt()
{
    [d->sql appendFormat:@">%@", d->placeholder];
    return *this;
}

BuildSql& BuildSql::greaterThanOrEqualTo(id value)
{
    do {
        if ([value isKindOfClass:[NSNumber class]] || d->joining) {
            [d->sql appendFormat:@">=%@",value];
        } else if ([value isKindOfClass:[NSString class]]) {
            [d->sql appendFormat:@">='%@'",value];
        } else {
            NSCAssert(NO, @"SQL: unsupport type:%@", [value class]);
        }
    } while (0);
    return *this;
}

BuildSql& BuildSql::nlt()
{
    [d->sql appendFormat:@">=%@", d->placeholder];
    return *this;
}

BuildSql& BuildSql::lessThan(id value)
{
    do {
        if ([value isKindOfClass:[NSNumber class]] || d->joining) {
            [d->sql appendFormat:@"<%@",value];
        } else if ([value isKindOfClass:[NSString class]]) {
            [d->sql appendFormat:@"<'%@'",value];
        } else {
            NSCAssert(NO, @"SQL: unsupport type:%@", [value class]);
        }
    } while (0);
    return *this;
}

BuildSql& BuildSql::lt()
{
    [d->sql appendFormat:@"<%@", d->placeholder];
    return *this;
}

BuildSql& BuildSql::lessThanOrEqualtTo(id value)
{
    do {
        if ([value isKindOfClass:[NSNumber class]] || d->joining) {
            [d->sql appendFormat:@"<=%@",value];
        } else if ([value isKindOfClass:[NSString class]]) {
            [d->sql appendFormat:@"<='%@'",value];
        } else {
            NSCAssert(NO, @"SQL: unsupport type:%@", [value class]);
        }
    } while (0);
    return *this;
}

BuildSql& BuildSql::ngt()
{
    [d->sql appendFormat:@"<=%@", d->placeholder];
    return *this;
}

BuildSql& BuildSql::And(id valueOrField)
{
    do {
        NSString *format = nil;
        if (d->betweening) {
            if ([valueOrField isKindOfClass:[NSNumber class]]) {
                format = @"%@";
            } else if ([valueOrField isKindOfClass:[NSString class]]) {
                format = @"'%@'";
            } else {
                NSCAssert(NO, @"Unexpected contained object type.");
                break;
            }
            d->betweening = 0;
        } else {
            format = @"%@";
        }
        [d->sql appendString:@" AND "];
        [d->sql appendFormat:format, valueOrField];
    } while (0);
    return *this;
}

BuildSql& BuildSql::Or(NSString *feild)
{
    [[d->sql append:@" OR "] append:feild];
    return *this;
}

BuildSql& BuildSql::field_impl(NSString *field, bool hasNext)
{
    if (d->selectedArgs) {
        d->selectedArgs = 0;
        [d->sql appendString:@", "];
    }
    [d->sql appendString:field];
    if (d->inserting) {
        ++d->insertCount;
    }
    if (hasNext) {
        [d->sql appendString:@", "];
    }
    return *this;
}

BuildSql& BuildSql::fieldPh_impl(NSString *field, bool hasNext)
{
    [[d->sql append:field] appendString:@"=?"];
    if (hasNext) {
        [d->sql appendString:@", "];
    }
    return *this;
}

BuildSql& BuildSql::select_impl(NSString *field, bool hasNext)
{
    [d->sql appendString:field];
    if (hasNext) {
        [d->sql appendString:@", "];
    }
    d->selectedArgs = 1;
    return *this;
}

void BuildSql::select()
{
    d->selecting = 1;
    [d->sql appendString:@"SELECT "];
}

#pragma mark - constraint
BuildSql& BuildSql::nonull()
{
    [d->sql appendString:@" NOT NULL"];
    return *this;
}

BuildSql& BuildSql::unique()
{
    [d->sql appendString:@" UNIQUE"];
    return *this;
}

BuildSql& BuildSql::unique(NSString *field)
{
    do {
        if (!d->creating) {
            NSCAssert(NO, @"Tail-UNIQUE operation is just used in CREATE statement.");
            break;
        }
        if (!d->creatingHasColumn) {
            NSCAssert(NO, @"No column!");
            break;
        }
        [d->sql appendFormat:@",UNIQUE (%@)", field];
    } while (0);
    return *this;
}

BuildSql& BuildSql::primaryKey()
{
    [d->sql appendString:@" PRIMARY KEY"];
    return *this;
}

BuildSql& BuildSql::primaryKey(NSString *field)
{
    do {
        if (!d->creating) {
            NSCAssert(NO, @"Tail-PRIMARY KEY operation is just used in CREATE statement.");
            break;
        }
        if (!d->creatingHasColumn) {
            NSCAssert(NO, @"No column!");
            break;
        }
        [d->sql appendFormat:@",PRIMARY KEY (%@)", field];
    } while (0);
    return *this;
}

BuildSql& BuildSql::foreignKey(NSString *field, NSString *toField, NSString *ofAnotherTable)
{
    do {
        if (!d->creating) {
            NSCAssert(NO, @"Tail-FOREIGN KEY operation is just used in CREATE statement.");
            break;
        }
        if (!d->creatingHasColumn) {
            NSCAssert(NO, @"No column!");
            break;
        }
        [d->sql appendFormat:@",FOREIGN KEY (%@) REFERENCES %@(%@)",
                             field, ofAnotherTable, toField];
    } while (0);
    return *this;
}

BuildSql& BuildSql::check(NSString *statement)
{
    do {
        if (!d->creating) {
            NSCAssert(NO, @"Tail-CHECK operation is just used in CREATE statement.");
            break;
        }
        if (!d->creatingHasColumn) {
            NSCAssert(NO, @"No column!");
            break;
        }
        [d->sql appendFormat:@" CHECK (%@)", statement];
    } while (0);
    return *this;
}

BuildSql& BuildSql::checks()
{
    do {
        if (!d->creating) {
            NSCAssert(NO, @"Tail-CHECK operation is just used in CREATE statement.");
            break;
        }
        if (!d->creatingHasColumn) {
            NSCAssert(NO, @"No column!");
            break;
        }
        [d->sql appendString:@" CHECK ("];
    } while (0);
    return *this;
}

BuildSql& BuildSql::checke()
{
    do {
        if (!d->creating) {
            NSCAssert(NO, @"Tail-CHECK operation is just used in CREATE statement.");
            break;
        }
        if (!d->creatingHasColumn) {
            NSCAssert(NO, @"No column!");
            break;
        }
        [d->sql appendString:@")"];
    } while (0);
    return *this;
}

BuildSql& BuildSql::Default(NSString *statement)
{
    do {
        if (!d->creating) {
            NSCAssert(NO, @"DEFAULT operation is just used in CREATE statement.");
            break;
        }
        if (!d->creatingHasColumn) {
            NSCAssert(NO, @"No column!");
            break;
        }
        [d->sql appendString:@" DEFAULT "];
        if (d->lastTypeOfField >= SqlTypeVarchar && d->lastTypeOfField <= SqlTypeText) {
            [d->sql appendFormat:@"'%@'", statement];
        } else {
            [d->sql appendString:statement];
        }
    } while (0);
    return *this;
}

#pragma mark - advance
BuildSql& BuildSql::like(NSString *value)
{
    [d->sql appendFormat:@" LIKE '%@'", value];
    return *this;
}

BuildSql& BuildSql::top(NSNumber *number)
{
    NSCAssert(number, @"Illegal param [number] is null.");
    do {
        const char *type = number.objCType;
        if (!strcmp(type, @encode(double)) || !strcmp(type, @encode(float))) {
            double v = number.doubleValue;
            if (v < 0 || v > 1) {
                NSCAssert(NO, @"Unexpected limit. [0,1] wanted.");
                break;
            }
            v *= 100;
            [d->sql appendFormat:@"SELECT TOP %d PERCENT ", (int)v];
        } else {
            [d->sql appendFormat:@"SELECT TOP %@ " , number];
        }
        d->selecting = 1;
    } while (0);
    return *this;
}

BuildSql& BuildSql::limit(uint32_t start, uint32_t count)
{
    [d->sql appendFormat:@" LIMIT %u,%u", start, count];
    return *this;
}

BuildSql& BuildSql::in(NSArray *numberOrStringValues)
{
    NSCAssert(numberOrStringValues.count, @"Illegal param integerOrStringValues.count = 0.");
    id obj = numberOrStringValues.firstObject;
    NSString *format = nil;
    if ([obj isKindOfClass:[NSNumber class]]) {
        format = @"%@";
    } else if ([obj isKindOfClass:[NSString class]]) {
        format = @"'%@'";
    }
    NSCAssert(format, @"Unexpected contained object type.");
    [d->sql appendString:@" IN ("];
    BOOL first = YES;
    for (id o in numberOrStringValues) {
        if (first) {
            first = NO;
        } else {
            [d->sql appendString:@","];
        }
        [d->sql appendFormat:format, o];
    }
    [d->sql appendString:@")"];
    return *this;
}

BuildSql& BuildSql::between(id value)
{
    [d->sql appendString:@" BETWEEN "];
    NSString *format = nil;
    if ([value isKindOfClass:[NSNumber class]]) {
        format = @"%@";
    } else if ([value isKindOfClass:[NSString class]]) {
        format = @"'%@'";
    }
    [d->sql appendFormat:format, value];
    d->betweening = 1;
    return *this;
}

BuildSql& BuildSql::as(NSString *alias)
{
    [[d->sql append:@" AS "] appendString:alias];
    return *this;
}

BuildSql& BuildSql::joinOn(NSString *table, SqlJoinType type, JoinWay oi/* = OUTER*/)
{
    do {
        NSCAssert(table.length, @"Illegal param[table]");
        NSString *format = nil;
        switch (type) {
            case SqlJoinTypeNormal:
                format = @" %@ JOIN %@ ON ";
                break;
            case SqlJoinTypeLeft:
                format = @" LEFT %@ JOIN %@ ON ";
                break;
            case SqlJoinTypeRight:
                format = @" RIGHT %@ JOIN %@ ON ";
                break;
            case SqlJoinTypeFull:
                format = @" FULL %@ JOIN %@ ON ";
                break;
        }
        if (!format) {
            NSCAssert(NO, @"Unexpected SqlJoinType, code:%@", @(type));
            break;
        }
        NSString *joinway = nil;
        switch (oi) {
            case OUTER:
                joinway = @"OUTER";
                break;
            case INNER:
                joinway = @"INNER";
                break;
            case CROSS:
                joinway = @"CROSS";
                break;
        }
        if (!joinway) {
            NSCAssert(NO, @"Unexpected JoinWay, code:%@", @(oi));
            break;
        }
        NSString *sql = [NSString stringWithFormat:format, joinway, table];
        [d->sql appendString:sql];
        d->joining = 1;
    } while(0);
    return *this;
}

BuildSql& BuildSql::Union(bool recur/* = NO*/)
{
    do {
        if (!d->selecting) {
            NSCAssert(NO, @"Union operation is just used in SELECT statement.");
            break;
        }
        [d->sql appendString:@" UNION "];
        if (recur) {
            [d->sql appendString:@"ALL "];
        }
    } while (0);
    return *this;
}

BuildSql& BuildSql::into(NSString *table)
{
    do {
        if (!table.length) {
            NSCAssert(NO, @"Illegal param[table]");
            break;
        }
        if (!d->selecting) {
            NSCAssert(NO, @"SELECT INTO operation is just used in SELECT statement.");
            break;
        }
        [d->sql appendFormat:@" INTO %@", table];
    } while (0);
    return *this;
}

BuildSql& BuildSql::createIndex(NSString *indexName,
                                NSString *onField,
                                NSString *ofTable,
                                bool unique/* = false*/)
{
    NSString *format = nil;
    if (unique) {
        format = @"CREATE UNIQUE INDEX %@ ON %@(%@)";
    } else {
        format = @"CREATE INDEX %@ ON %@(%@)";
    }
    [d->sql appendFormat:format, indexName, ofTable, onField];
    return *this;
}

BuildSql& BuildSql::isnull()
{
    [d->sql appendString:@" IS NULL"];
    return *this;
}
BuildSql& BuildSql::isnnull()
{
    [d->sql appendString:@" IS NOT NULL"];
    return *this;
}

#pragma mark - unsql
bool BuildSql::isFinished() const
{
    return d->isFinished;
}

void BuildSql::end()
{
    do {
        if (d->isFinished) {
            NSCAssert(NO, @"SQL: has finished!");
            break;
        }
        if (d->creating) {
            this->scopee();
            d->creating = 0;
        }
        [d->sql appendString:@";"];
        d->isFinished = 1;
    } while (0);
}

BuildSql& BuildSql::reset()
{
    d->clean();
    return *this;
}

NSString* BuildSql::cacheForKey(NSString *key) const
{
    NSString *sql = nil;
    do {
        if (!d->cache_sql) {
            break;
        }
        sql = [d->cache_sql objectForKey:key];
    } while (0);
    return sql;
}
NSString* BuildSql::setCacheForKey(NSString *key)
{
#if defined(__OBJC__)
    if (cached(key)) {
        NSString *reason = [NSString stringWithFormat:@"Repeat cache for key(%@). Check you code.", key];
        @throw [NSException exceptionWithName:@"NSGenericException"
                                       reason:reason
                                     userInfo:nil];
    }
#endif
    if (!d->cache_sql) {
        d->cache_sql = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    NSString *object = d->sql.copy;
    [d->cache_sql setObject:object forKey:key];
    return object.copy;
}

bool BuildSql::cached(NSString *key) const
{
    return [d->cache_sql objectForKey:key] != nil;
}

NSDictionary<NSString *, NSString *> *BuildSql::caches() const
{
    return d->cache_sql.copy;
}

@implementation NSMutableString (append)

- (NSMutableString *)append:(NSString *)aString
{
    [self appendString:aString];
    return self;
}

@end
