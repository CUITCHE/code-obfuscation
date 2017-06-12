//
//  main.m
//  CO-iOS
//
//  Created by hejunqiu on 2017/6/12.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "COMethod.h"
#include <objc/runtime.h>

static NSMutableDictionary<NSString *, NSMutableArray<COMethod *> *> *cache = nil;

void loop();

int main(int argc, char * argv[]) {
    @autoreleasepool {
        loop();
        NSString *str = [NSString stringWithFormat:@"%@", cache];
        NSError *error = nil;
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.txt"];
        [str writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
        NSLog(@"path:%@", path);
        if (error) {
            NSLog(@"%@", error);
        }
        path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.data"];
        [NSKeyedArchiver archiveRootObject:cache toFile:path];
        NSData *data = [NSData dataWithContentsOfFile:path];
        // check
        id check = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([cache isEqualToDictionary:check]) {
            NSLog(@"Vaild!");
        } else {
            NSLog(@"Invaild!");
        }
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

void loop ()
{
    int num = objc_getClassList(NULL, 0);
    Class clazzs[num];
    num = objc_getClassList(clazzs, num);
    cache = [NSMutableDictionary dictionaryWithCapacity:num];

    Class *p = &clazzs[0];
    Class *end = clazzs + num;
    do {
        NSMutableArray<COMethod *> *comethods = [NSMutableArray array];
        unsigned int count = 0;
        Method *method = class_copyMethodList(*p, &count);
        for (unsigned int i=0; i<count; ++i) {
            Method m = method[i];
            COMethod *com = [COMethod methodWithName:NSStringFromSelector(method_getName(m))];
            for (NSString *name in [com.method componentsSeparatedByString:@":"]) {
                if (name.length) {
                    COSelectorPart *sel = [COSelectorPart selectorWithName:name];
                    [com addSelector:sel];
                }
            }
            [comethods addObject:com];
        }
        [cache setObject:comethods forKey:NSStringFromClass(*p)];
    } while (++p < end);
    NSLog(@"end...");
}

