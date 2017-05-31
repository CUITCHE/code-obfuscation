//
//  COFileAnalysis.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface COFileAnalysis : NSObject

- (instancetype)initWithFilepaths:(NSArray<NSString *> *)filepaths;
- (void)start;

@end
