//
//  main.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COObfuscationManager.h"
#import "CodeObfuscation-Swift.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        COObfuscationManager *manager = [COObfuscationManager new];
        [manager goWithRootPath:Arguments.arguments.rootpath];
        NSLog(@"END..");
    }
    return 0;
}

int printlnInStderr(NSString *text) {
    const char *str = text.UTF8String;
    return fprintf(stderr, "%s\n", str);
}

int println(NSString *colorText, NSString *otherText) {
    if (!colorText) {
        return fprintf(stderr, "%s\n", otherText.UTF8String);
    }
    return fprintf(stderr, "\e[0;1m%s\e[0m%s\n", colorText.UTF8String, otherText.UTF8String);
}
