# buildSQL
基于C++和Objective-C的buildSQL，可以用代码语言来build一条SQL语句。
# 简介
某天，我写了很多SQL语句，实在受不了了，就有了buildSQL。在有代码提示的情况下，写起来会更爽，阅读这样的SQL语句也更清晰明了。
# 如何使用
将`BuildSql.h`和`BuildSql.mm`包含进你的工程，并在包含`BuildSql.h`的文件的后缀名改为`mm`即可。
具体用法：
```Objective-C
// 不用把BuildSql对象建立在堆上，栈变量的点语法有助于阅读。
BuildSql sqlBuilder; // 另外一个构造函数是BuildSql(@"@")，传入的参数起到placeholder作用
// select
sqlBuilder.select(@"field0", @"field1", @"field2").from(@"table").where(@"id").equalTo(@(1)).And(@"type").lessThan(@(9)).end();
// sames to 'SELECT field0, field1, field2 FROM table WHERE id=1 AND type<9;'

// insert into
sqlBuilder.insertInto(@"table").field(@"field0", @"field1", @"field2", @"field3").values();
// sames to 'INSERT INTO table(field0, field1, field2, field3) VALUES(?,?,?,?);'

// update
sqlBuilder.update(@"table").fieldPh(@"field0", @"field1", @"field2", @"field3").where(@"name").equalTo(@"buildSql").end();
// sames to 'UPDATE table SET field0=?, field1=?, field2=?, field3=? WHERE name='buildSql';'

// delete
sqlBuilder.Delete(@"table").where(@"id").greaterThan(@1001).Or(@"id").lessThanOrEqualtTo(@2001);
// sames to 'DELETE FROM table WHERE id>1001 OR id<=2001'

// order by
sqlBuilder.select(@"field0", @"field1", @"field2").from(@"table").where(@"id").equalTo(@(1)).And(@"type").lessThan(@(9)).orderBy(@"field0").end();
// sames to 'SELECT field0, field1, field2 FROM table WHERE id=1 AND type<9 ORDER BY field0;'

// create table
sqlBuilder.create(@"table").
    column(@"id", SqlTypeInteger).primaryKey().
    column(@"name", SqlTypeVarchar, bs_max(200)).nonull().
    column(@"number", SqlTypeDecimal, bs_precision(20, 8)).nonull().end(); // 这儿的end()调用是必须的
// sames to 'CREATE TABLE IF NOT EXISTS table(id Integer PRIMARY KEY,name Varchar(200) NOT NULL,number Decimal(20,8) NOT NULL);'
```
更多的用法，请参考我编写的[测试用例](/buildSQLTest/buildSQLTest.mm)。

BuildSql可以被多次使用，只需要在使用前调用`reset()`就可以恢复到初始状态。
# 使用要求
* Only support [C]. 由于使用了Objective-C的`NSString`，所以暂时只支持[C]，以后会考虑改成纯C++的构建。
* 你需要知道必要的SQL语法，请参考[SQL 教程](http://www.w3school.com.cn/sql/)

# 注意
* buildSql基本上不会去检查语法错误！
* buildSql只会简单提示一些可能会影响到sql build时的小错误。

# 未实现
* 「drop」、「alter」
* 有的组合代码需要合并优化

# 其它
欢迎各位对此感兴趣的社区同仁共同维护buildSQL。欢迎大家提bug issue。
