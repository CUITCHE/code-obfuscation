//
//  COObfuscationManager.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/31.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface COObfuscationManager : NSObject

- (void)goWithRootPath:(NSString *)rootpath;

- (void)goWithArguments:(NSArray<NSString *> *)arguments;

@end
