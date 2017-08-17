//
//  BuildSql.h
//  buildSQL
//
//  Created by hejunqiu on 16/6/30.
//  Copyright © 2016年 CHE. All rights reserved.
//

#ifndef BuildSql_hpp
#define BuildSql_hpp

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, Order) {
    /// 升序
    ASC,
    /// 降序
    DESC
};

typedef NS_ENUM(uint8_t, JoinWay) {
    /// 外联
    OUTER,
    /// 内联
    INNER,
    /// 交差集
    CROSS
};

typedef NS_ENUM(NSInteger, SqlType) {
#pragma mark INTEGER in SQLITE
    SqlTypeInt,
    SqlTypeTinyInt,
    SqlTypeSmallInt,
    SqlTypeMediumInt,
    SqlTypeBigInt,
    SqlTypeUnsignedBigInt,
    SqlTypeInt2,
    SqlTypeInt8,
    SqlTypeInteger,

#pragma mark TEXT in SQLITE
    SqlTypeVarchar,
    SqlTypeNVarchar,
    SqlTypeChar,
    SqlTypeNChar,
    SqlTypeCLOB,
    SqlTypeText,

#pragma mark REAL in SQLITE
    SqlTypeDouble,
    SqlTypeFloat,
    SqlTypeReal,

#pragma mark NUMBERIC in SQLITE
    SqlTypeDecimal,
    SqlTypeDate,
    SqlTypeDateTime,
    SqlTypeBoolean,
    SqlTypeNumeric,

#pragma mark NONE in SQLITE
    SqlTypeBlob
};

typedef NS_ENUM(NSInteger, SqlJoinType) {
    /// As JOIN
    SqlJoinTypeNormal,
    /// As LEFT JOIN
    SqlJoinTypeLeft,
    /// As RIGHT JOIN
    SqlJoinTypeRight,
    /// As FULL JOIN
    SqlJoinTypeFull
};

// __capacity begin
typedef struct {
    uint32_t wholeMax : 16;
    uint32_t rightMax : 16;
#if __LP64__
    uint32_t reserved;
#endif
}__capacity;

NS_INLINE uint32_t bs_whole(__capacity c) {return (((uint32_t)c.wholeMax)<<16) | c.rightMax;}
NS_INLINE __capacity bs_max(uint32_t val) {return {((val&0xFFFF0000)>>16), (val&0x0000FFFF)};}
NS_INLINE __capacity bs_precision(uint16_t whole, uint16_t right) {return {.wholeMax=whole,.rightMax=right};};
// __capacity end

#ifdef BS_USE_SQLITE
#define BS_USE_SQLITE_META
#endif

#ifdef BS_USE_MYSQL
#define BS_USE_MYSQL_META
#endif

class BuildSql
{
public:
    BuildSql(NSString *placehodler = @"?");
    ~BuildSql();

    template<typename... Args>
    BuildSql& field(NSString *field, Args... args);
    template<typename... Args>
    BuildSql& fieldPh(NSString *field, Args... args);

    template<typename... Args>
    BuildSql& select(Args... args);

    BuildSql& from(NSString *table);
    BuildSql& from(NSArray<NSString *> *tables);
    BuildSql& where(NSString *field);

    BuildSql& Delete(NSString *table);
    BuildSql& update(NSString *table);

    BuildSql& insertInto(NSString *table);
    void values(); // 如果本条sql使用了insert，那么将会自动插入与insert相同数量的placeholder

    BuildSql& scopes(); // '('开始标记
    BuildSql& scopee(); // ')'结束标记

    BuildSql& value(id val);

    BuildSql& orderBy(NSString *field, Order order = ASC);

    BuildSql& create(NSString *table);
    BuildSql& column(NSString *name, SqlType type, __capacity capacity = {0,0});
#pragma mark - final sql
    NSString* sql() const;

#pragma mark - operation
    /// same as equalTo.
    BuildSql& et(id value){return equalTo(value);}
    BuildSql& equalTo(id value);
    /// append '= ?', '?' is placeholder.
    BuildSql& et();

    /// same as notEqualTo.
    BuildSql& net(id value){return notEqualTo(value);}
    BuildSql& notEqualTo(id value);
    BuildSql& net();

    /// same as greaterThan.
    BuildSql& gt(id value){return greaterThan(value);}
    BuildSql& greaterThan(id value);
    BuildSql& gt();

    /// same as greaterThanOrEqualTo.
    BuildSql& nlt(id value){return greaterThanOrEqualTo(value);}
    BuildSql& greaterThanOrEqualTo(id value);
    BuildSql& nlt();

    /// same as lessThan.
    BuildSql& lt(id value){return lessThan(value);}
    BuildSql& lessThan(id value);
    BuildSql& lt();

    /// same as lessThanOrEqualtTo.
    BuildSql& ngt(id value){return lessThanOrEqualtTo(value);}
    BuildSql& lessThanOrEqualtTo(id value);
    BuildSql& ngt();

    BuildSql& And(id valueOrField); // like and
    BuildSql& Or(NSString *feild);  // like or

#pragma mark - constraint
    BuildSql& nonull();

    BuildSql& unique();
    BuildSql& unique(NSString *field);

    BuildSql& primaryKey();
    BuildSql& primaryKey(NSString *field);

    BuildSql& foreignKey(NSString *field, NSString *toField, NSString *ofAnotherTable);
#if __ASSERT_MACROS_DEFINE_VERSIONS_WITHOUT_UNDERSCORES
    #if defined(check)
        #undef check
    #endif
#endif
    BuildSql& check(NSString *statement);
    BuildSql& checks();
    BuildSql& checke();

    BuildSql& Default(NSString *statement);
#pragma mark - advance
    BuildSql& like(NSString *value);
    /**
     * @author hejunqiu, 16-07-03 22:07:51
     *
     * Build a statement-sql for a clause of SELECT: 'TOP 100' or 'TOP 50 PERCENT'.
     * Such as 'SELECT TOP 2 * FROM Persons', 'SELECT TOP 50 PERCENT * FROM Persons'.
     *
     * @param number An object of NSNumber presents integer or float value. If number
     * is a float value, it's limit between 0 and 1.
     *
     * @return An object of BuildSql.
     */
    BuildSql& top(NSNumber *number);
    BuildSql& limit(uint32_t start, uint32_t count);

    BuildSql& in(NSArray *numberOrStringValues);
    BuildSql& between(id value);
    BuildSql& as(NSString *alias);
    BuildSql& joinOn(NSString *table, SqlJoinType type, JoinWay oi = OUTER);
    BuildSql& Union(bool recur = NO);
    /// Just wrote after SELECT statement. And unsupport that wrote to another database.
    BuildSql& into(NSString *table);
    BuildSql& createIndex(NSString *indexName, NSString *onField, NSString *ofTable, bool unique = false);

#pragma mark - NULLs
    BuildSql& isnull();
    BuildSql& isnnull();
#pragma mark - unsql
    bool isFinished() const;
    void end();
    BuildSql& reset();
    NSString* cacheForKey(NSString *key) const;
    NSString* setCacheForKey(NSString *key);
    bool cached(NSString *key) const;
    NSDictionary<NSString *, NSString *> *caches() const;
protected:
    BuildSql& field(){return *this;}
    BuildSql& field_impl(NSString *field, bool hasNext);

    BuildSql& fieldPh(){return *this;}
    BuildSql& fieldPh_impl(NSString *field, bool hasNext);

    BuildSql& select_extend(){return *this;}
    BuildSql& select_impl(NSString *field, bool hasNext);
    template <typename... Args>
    BuildSql& select_extend(NSString *field, Args... args);
    void select();
private:
    struct SqlMakerPrivateData *d;
};

template <typename... Args>
BuildSql& BuildSql::field(NSString *f, Args... args)
{
    field_impl(f, sizeof...(args) > 0);
    return field(args...);
}

template <typename... Args>
BuildSql& BuildSql::fieldPh(NSString *f, Args... args)
{
    fieldPh_impl(f, sizeof...(args) > 0);
    return fieldPh(args...);
}

template <typename... Args>
BuildSql& BuildSql::select(Args... args)
{
    select();
    return select_extend(args...);
}

template <typename... Args>
BuildSql& BuildSql::select_extend(NSString *field, Args... args)
{
    select_impl(field, sizeof...(args) > 0);
    return select_extend(args...);
}

#pragma mark -[C]
@interface NSMutableString (append)

- (NSMutableString *)append:(NSString *)aString;

@end

#pragma mark - Useful

#ifndef bs_set_cache
#define bs_set_cache(obj, lineOffset) (obj).setCacheForKey(@(__LINE__ + lineOffset).stringValue)
#endif

#ifndef bs_get_cache
#define bs_get_cache(obj) obj.cacheForKey(@(__LINE__).stringValue)
#endif

#endif /* BuildSql_hpp */
