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
@property (nonatomic, strong) NSString *infoPlistFilepath;

/// [-offset] 设置混淆名字的偏移量。默认为0，即每次都是随机值的偏移。
@property (nonatomic) NSUInteger obfuscationOffset;

/// [-release|-debug] true: 只在release下才会替换混淆命名；false: 任何时候都会启用混淆命名。默认false。
@property (nonatomic) BOOL onlyDebug;

/// [-db] 混淆字符映射的字典存放目录。默认是本程序执行的目录。
@property (nonatomic, strong) NSString *dbFilepath;

/// [-root] 需要混淆的工程路径。默认为当前运行根目录。
@property (nonatomic, strong) NSString *rootpath;

@end

NS_ASSUME_NONNULL_END
