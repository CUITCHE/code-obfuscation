//
//  objc.m
//  Gen
//
//  Created by hejunqiu on 2017/8/28.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

#import "objc.h"
#include <objc/runtime.h>
#import "Gen-Swift.h"

NSDictionary<NSString *, NSArray<Function *> *>* EnumerateObjectiveClass()
{
    int num = objc_getClassList(NULL, 0);
    Class clazzs[num];
    num = objc_getClassList(clazzs, num);
    NSMutableDictionary<NSString *, NSMutableArray<Function *> *> *cache = [NSMutableDictionary dictionaryWithCapacity:num];

    Class *p = &clazzs[0];
    Class *end = clazzs + num;
    do {
        NSString *classname = @(class_getName(*p));
        if ([classname containsString:@"."]) {
            continue;
        }
        NSMutableArray<Function *> *comethods = [NSMutableArray array];
        unsigned int count = 0;
        Method *method = class_copyMethodList(*p, &count);
        for (unsigned int i=0; i<count; ++i) {
            Method m = method[i];
            Function *com = [[Function alloc] initWithName:NSStringFromSelector(method_getName(m)) location:NSMakeRange(0, 0)];
            [comethods addObject:com];
        }
        free(method);
        [cache setObject:comethods forKey:classname];
    } while (++p < end);
    [cache removeObjectForKey:@"AppDelegate"];
    [cache removeObjectForKey:@"ViewController"];
    return cache;
}
