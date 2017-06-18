//
//  gen.cpp
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/18.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COMethod.h"
#include <objc/runtime.h>

#import "AppDelegate.h"
#import "ViewController.h"

static NSMutableDictionary<NSString *, NSMutableArray<COMethod *> *> *cache = nil;

static void loop()
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
//            for (NSString *name in [com.method componentsSeparatedByString:@":"]) {
//                if (name.length) {
//                    COSelectorPart *sel = [COSelectorPart selectorWithName:name];
//                    [com addSelector:sel];
//                }
//            }
            [comethods addObject:com];
        }
        [cache setObject:comethods forKey:@(class_getName(*p))];
    } while (++p < end);
}

static BOOL validation()
{
    NSString *str = [NSString stringWithFormat:@"%@", cache];
    NSError *error = nil;
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.txt"];
    [str writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"path:%@", path);
    if (error) {
        NSLog(@"%@", error);
        return NO;
    }
    path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.data"];
    [NSKeyedArchiver archiveRootObject:cache toFile:path];
    NSData *data = [NSData dataWithContentsOfFile:path];
    // check
    id check = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return [cache isEqualToDictionary:check];
}

NSMutableString *file_buffer = nil;
NS_INLINE void gen();
__attribute__((constructor)) void ________genCode()
{
    loop();
    if (validation()) {
        NSLog(@"Vaild!");
    } else {
        NSLog(@"Invaild!");
    }
    // 移除AppDelegate, ViewController
    [cache removeObjectForKey:NSStringFromClass([AppDelegate class])];
    [cache removeObjectForKey:NSStringFromClass([ViewController class])];
    file_buffer = [NSMutableString string];
    gen();
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"GenMetaData.cpp"];
    NSError *error = nil;
    [file_buffer writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    file_buffer = nil;
    NSLog(@"END...");
}

//////////////////////
NS_INLINE void writeline(NSString *str);

NS_INLINE void write_prepare()
{
    writeline([NSString stringWithFormat:@"/////  For iOS SDK %@\n", [NSProcessInfo processInfo].operatingSystemVersionString]);
    writeline(@"#ifndef structs_h\n#define structs_h\n");

    writeline(@"struct __method__ {\n"\
              "    const char *name;\n"\
              "};\n");

    writeline(@"struct __method__list {\n"\
              "    unsigned int reserved;\n"\
              "    unsigned int count;\n"\
              "    struct __method__ methods[0];\n"\
              "};\n");

    writeline(@"struct __class__ {\n"\
              "    struct __class__ *superclass;\n"\
              "    const char *name;\n"\
              "    const struct __method__list *method_list;\n"\
              "};\n");

    writeline(@"#ifndef CO_EXPORT");
    writeline(@"#define CO_EXPORT extern \"C\"");
    writeline(@"#endif");
}

NS_INLINE void _write(NSString * clazzName, NSUInteger methodcount, NSString *methoddesc)
{
    writeline(@"");
    writeline([NSString stringWithFormat:@"/// Meta data for %@", clazzName]);
    writeline(@"");
    writeline(@"static struct /*__method__list_t*/ {");
    writeline(@"    unsigned int entsize;");
    writeline(@"    unsigned int method_count;");
    writeline([NSString stringWithFormat:@"    struct __method__ method_list[%zu];", methodcount ?: 1]);
    writeline([NSString stringWithFormat:@"} _CO_METHODNAMES_%@_$ __attribute__ ((used, section (\"__DATA,__co_const\"))) = {", clazzName]);
    writeline(@"    sizeof(__method__),");
    writeline([NSString stringWithFormat:@"    %zu,", methodcount]);
    writeline([NSString stringWithFormat:@"    {%@}\n};", methoddesc]);

    Class clazz = NSClassFromString(clazzName);
    Class superClass = class_getSuperclass(clazz);
    NSString *super_class_t = nil;
    if (superClass) {
        super_class_t = [NSString stringWithFormat:@"_CO_CLASS_$_%s", class_getName(superClass)];
        writeline([NSString stringWithFormat:@"\nCO_EXPORT struct __class__ %@;", super_class_t]);
    }
    writeline([NSString stringWithFormat:@"CO_EXPORT struct __class__ _CO_CLASS_$_%@ __attribute__ ((used, section (\"__DATA,__co_data\"))) = {", clazzName]);
    if (super_class_t) {
        writeline([NSString stringWithFormat:@"    &%@,", super_class_t]);
    } else {
        writeline(@"    0,");
    }
    writeline([NSString stringWithFormat:@"    \"%@\",", clazzName]);
    writeline([NSString stringWithFormat:@"    (const struct __method__list *)&_CO_METHODNAMES_%@_$\n};", clazzName]);
}

NS_INLINE void write_tail()
{
    writeline([NSString stringWithFormat:@"\nCO_EXPORT struct __class__ *L_CO_LABEL_CLASS_$[%zu] __attribute__((used, section (\"__DATA, __co_classlist\"))) = {", cache.count]);
    [cache enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<COMethod *> * _Nonnull obj, BOOL * _Nonnull stop)
     {
        writeline([NSString stringWithFormat:@"    &_CO_CLASS_$_%@,", key]);
     }];
    writeline(@"};");

    writeline([NSString stringWithFormat:@"\nCO_EXPORT struct /*__image_info*/ {\n"\
               "    const char *version;\n"\
               "    unsigned long size;\n"\
               "} _CO_CLASS_IMAGE_INFO_$ __attribute__ ((used, section (\"__DATA,__co_const\"))) = {\n"\
               "    \"%@\",\n"\
               "    %zu\n"\
               "};", [NSProcessInfo processInfo].operatingSystemVersionString, cache.count]);

    writeline(@"\n#endif");
}

NS_INLINE void writeline(NSString *str)
{
    [file_buffer appendFormat:@"%@\n", str];
}

NS_INLINE void gen()
{
    write_prepare();
    [cache enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<COMethod *> * _Nonnull obj, BOOL * _Nonnull stop) {
         NSMutableArray<NSString *> *methods = [NSMutableArray arrayWithCapacity:obj.count];
         for (COMethod *m in obj) {
            [methods addObject:m.method];
         }
         _write(key, obj.count, [NSString stringWithFormat:@"{\"%@\"}", [methods componentsJoinedByString:@"\"},{\""]]);
     }];
    write_tail();
}
