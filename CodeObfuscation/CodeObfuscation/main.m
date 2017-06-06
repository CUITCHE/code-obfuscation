//
//  main.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COObfuscationManager.h"
#import "COArguments.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        COArguments *arguments = [COArguments argumentsWithExecuteArgs:argv argc:argc];
        COObfuscationManager *manager = [COObfuscationManager new];
        [manager goWithRootPath:arguments.rootpath];
        NSLog(@"END..");
    }
    return 0;
}
