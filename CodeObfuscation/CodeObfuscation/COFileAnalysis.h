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

- (instancetype)initWithFilepaths:(NSArray<NSString *> *)filepaths;
- (void)start;

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, COClass *> *clazzs;

@end
