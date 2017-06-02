//
//  COFileAnalysis.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class COClass;

@interface COFileAnalysis : NSObject

- (instancetype)initWithFilepaths:(NSArray<NSString *> *)filepaths writtenFilepath:(NSString *)cohFilepath;
- (void)start;

@property (nonatomic, strong, readonly) NSDictionary<NSString *, COClass *> *clazzs;
@property (nonatomic, strong, readonly) NSString *cohFilepath;

@end
