//
//  COArguments.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/6.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface COArguments : NSObject

+ (instancetype)argumentsWithExecuteArgs:(const char *_Nonnull*_Nonnull)argv argc:(int)argc;

/// app 标识符，例如：club.we-code.obfuscation，默认club.we-code.obfuscation
@property (nonatomic, strong, readonly, nullable) NSString *identifier;
@property (nonatomic, strong, readonly, nullable) NSString *appVersion;

/// [-id] info.plist的文件目录。默认为当前路径
@property (nonatomic, strong, readonly) NSString *infoPlistFilepath;

/// [-offset] 设置混淆名字的偏移量。默认为0。
@property (nonatomic, readonly) NSUInteger obfuscationOffset;

/// [-release|-debug] true: 只在release下才会替换混淆命名；false: 任何时候都会启用混淆命名。默认false。
@property (nonatomic, readonly) BOOL onlyDebug DEPRECATED_MSG_ATTRIBUTE("DO NOT support any more. Now Default if release");

/// [-db] 混淆字符映射的字典存放目录。默认是本程序执行的目录。
@property (nonatomic, strong, readonly) NSString *dbFilepath;

/// [-root] 需要混淆的工程路径。默认为当前运行根目录。
@property (nonatomic, strong, readonly) NSString *rootpath;

/// [-super] 检查当前类的方法属性是否与它的父类同名，如果同名会以父类为准。[自定义类]。默认false。
@property (nonatomic, readonly) BOOL supercheck;
/// [--strict=<true|false>] 在开启-super的情况下，如果继承链中含有iOS Kit中的类，则会对比其方法属性是否父类也存在。如果存在（包含私有方法），则会给出提示信息。默认false。
@property (nonatomic, readonly) BOOL strict;

/// [-st=<true|false>] 加强混淆力度。默认true
@property (nonatomic, readonly) BOOL st;

@property (nonatomic, strong) NSString *executedPath;
@end

NS_ASSUME_NONNULL_END
