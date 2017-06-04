//
//  COFileOutStream.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/3.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface COFileOutStream : NSObject

+ (instancetype)outStreamWithFilepath:(NSString *)filepath;

@property (nonatomic, readonly, getter=isNeedGenerateObfuscationCode) BOOL needGenerateObfuscationCode;

- (void)read;

- (BOOL)worthParsingFile:(NSString *)filecontent filename:(NSString *)filename;

- (void)begin;
- (void)writeObfuscation:(NSDictionary<NSString *, NSString *> *)code;
- (void)end;

@end

NS_ASSUME_NONNULL_END
