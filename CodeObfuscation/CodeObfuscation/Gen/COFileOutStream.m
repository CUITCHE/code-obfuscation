//
//  COFileOutStream.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/3.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COFileOutStream.h"
#import "global.h"
#import "NSString+COMD5.h"
#import "CodeObfuscation-Swift.h"

NSString *const COFOSFieldObfusedMD5 = @"filesold";
NSString *const COFOSFieldObfuseMD5  = @"files";
NSString *const COFOSFieldSelfMD5    = @"self";

@interface COFileOutStream ()
{
    NSString *_headerFilename;
    NSUInteger _selfLocation;
}

@property (nonatomic, strong) NSString *filepath;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *attributed;
@property (nonatomic, strong) NSString *originalFileContent;

@property (nonatomic, strong) NSMutableString *gen;

@property (nonatomic, strong) NSArray<NSString *> *relateFilepaths;

@end

@implementation COFileOutStream

+ (instancetype)outStreamWithFilepath:(NSString *)filepath
{
    return [[COFileOutStream alloc] initWithFilepath:filepath];
}

- (instancetype)initWithFilepath:(NSString *)filepath
{
    if (self = [super init]) {
        _originalFileContent = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
        if (!_originalFileContent) {
            println("%s is not exists.", filepath.UTF8String);
            return nil;
        }
        _filepath = filepath;
    }
    return self;
}

NS_INLINE NSString *_md5(NSString * _Nonnull content)
{
    NSString *str = [NSString stringWithFormat:@"%@%lu", content, content.length].md5;
    return str;
}

NS_INLINE NSString *_md5_for_self(NSString *content)
{
    NSRange range = [content rangeOfString:@"[self] = "];
    if (range.location == NSNotFound) {
        return nil;
    }
    range.location = NSMaxRange(range);
    range.length = 32;
    NSString *self = [content stringByReplacingCharactersInRange:range withString:@""];
    return self.md5;
}

- (void)read
{
    if (!_attributed) {
        _attributed = [NSMutableDictionary dictionary];
    } else {
        return;
    }
    NSUInteger cohFileSearchEndIndex = 0;
    NSScanner *scanner = [NSScanner scannerWithString:_originalFileContent];
    if ([scanner scanUpToString:@"[self] =" intoString:nil]) {
        cohFileSearchEndIndex = scanner.scanLocation;
        [scanner scanString:@"[self] =" intoString:nil];
        NSString *selfMd5 = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&selfMd5];
        if (selfMd5) {
            NSString *curCOHMd5 = _md5_for_self(_originalFileContent);
            self.attributed[COFOSFieldSelfMD5] = curCOHMd5;
            // coh文件校验
            if (![curCOHMd5 isEqualToString:selfMd5]) {
                _gen = [NSMutableString string];
            }
        } else {
            _gen = [NSMutableString string];
        }
    }

    // 扫描关联文件的md5值
    scanner = [NSScanner scannerWithString:[_originalFileContent substringToIndex:cohFileSearchEndIndex]];
    NSMutableDictionary<NSString *, NSString *> *oldmd5 = [NSMutableDictionary dictionary];
    while ([scanner scanUpToString:@"[" intoString:nil]) {
        [scanner scanString:@"[" intoString:nil];
        NSString *filename = nil;
        [scanner scanUpToString:@"]" intoString:&filename];

        [scanner scanUpToString:@"= " intoString:nil];
        [scanner scanString:@"= " intoString:nil];

        NSString *md5 = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&md5];
        if (filename && md5) {
            if (![filename isEqualToString:@"self"]) {
                oldmd5[filename] = md5;
            }
        }
    }
    self.attributed[COFOSFieldObfusedMD5] = oldmd5;
}

- (BOOL)worthParsingFile:(NSString *)filecontent filename:(NSString *)filename
{
    NSString *newmd5 = _md5(filecontent);
    NSMutableDictionary *newmd5s = self.attributed[COFOSFieldObfuseMD5];
    if (!newmd5s) {
        newmd5s = [NSMutableDictionary dictionary];
        self.attributed[COFOSFieldObfuseMD5] = newmd5s;
    }
    newmd5s[filename] = newmd5;
    if ([newmd5 isEqualToString:self.attributed[COFOSFieldObfusedMD5][filename]]) {
        // FIXME: 由于当前设计缺陷，暂且决策每次都需要重新生成混淆数据
        return YES;
    }
    if (!_gen) {
        _gen = [NSMutableString string];
    }
    return YES;
}

- (BOOL)isNeedGenerateObfuscationCode
{
    return !!_gen;
}

- (void)begin
{
    NSAssert(_gen, @"Logic error, you need not to generate code");
    NSAssert(_originalFileContent, @"No original data");

    static NSDateFormatter *fmtter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmtter = [[NSDateFormatter alloc] init];
        [fmtter setDateFormat:@"yyyy/MM/dd"];
    });

    // 写头部注释
    NSString *headerfilename = self.filepath.lastPathComponent;
    [_gen appendFormat:@"//\n//  %@\n", headerfilename];
    [_gen appendFormat:@"//  Code-Obfuscation Auto Generator\n\n"];
    [_gen appendFormat:@"//  Created by %@ on %@.\n", Arguments.arguments.executedPath.lastPathComponent, [fmtter stringFromDate:NSDate.new]];
    [_gen appendFormat:@"//  Copyright © 2102 year %@. All rights reserved.\n\n", Arguments.arguments.executedPath.lastPathComponent];

    [_gen appendFormat:@"//  DO NOT TRY TO MODIFY THIS FILE!\n"];
    NSDictionary *newmd5s = self.attributed[COFOSFieldObfuseMD5];
    [newmd5s enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [_gen appendFormat:@"//  [%@] = %@\n", key, obj];
    }];
    [_gen appendString:@"//  [self] = "];
    _selfLocation = _gen.length;

    NSString *headerfile = [headerfilename stringByReplacingOccurrencesOfString:@".coh"
                                                                     withString:@"_coh"];
    headerfile = headerfile.uppercaseString;
    _headerFilename = headerfile;

    // 写头文件header 宏
    [_gen appendFormat:@"#ifndef %@\n"
                        "#define %@\n\n", headerfile, headerfile];

    // 生成COF的必用宏
    [self _writeMacroHelper:@"CO_CONFUSION_CLASS"];
    [self _writeMacroHelper:@"CO_CONFUSION_CATEGORY"];
    [self _writeMacroHelper:@"CO_CONFUSION_PROPERTY"];
    [self _writeMacroHelper:@"CO_CONFUSION_METHOD"];

    // 尝试包含features头文件
    [_gen appendString:@"#if __has_include(\"CO-Features.h\")\n"];
    [_gen appendString:@"# include \"CO-Features.h\"\n"];
    [_gen appendString:@"#endif // __has_include\n\n"];

    [_gen appendString:@"#if !defined(DEBUG)\n"];
}

- (void)writeObfuscation:(NSDictionary<NSString *, NSString *> *)code
{
    NSAssert(_gen, @"Logic error, you need not to generate code");
    __weak typeof(self) weakSelf = self;
    [code enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [weakSelf _writeFakeText:obj realText:key];
    }];
}

- (void)end
{
    NSAssert(_gen, @"Logic error, you need not to generate code");
    [_gen appendString:@"#endif\n\n"];
    [_gen appendFormat:@"#endif /* %@ */", _headerFilename];

    NSString *md5 = _md5(_gen);
    [_gen insertString:[NSString stringWithFormat:@"%@\n\n", md5] atIndex:_selfLocation];

    NSError *error = nil;
    [_gen writeToFile:self.filepath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        println("%s", error.localizedDescription.UTF8String);
    }
}

- (void)_writeFakeText:(NSString *)fake realText:(NSString *)real
{
    [_gen appendFormat:@"#ifndef %@\n"
                        "#define %@ %@\n"
                        "#endif\n\n",real, real, fake];
}

- (void)_writeMacroHelper:(NSString *)macro
{
    [_gen appendFormat:@"#ifndef %@\n"
                        "# define %@\n"
                        "#endif // !%@\n\n",macro, macro, macro];
}
@end
