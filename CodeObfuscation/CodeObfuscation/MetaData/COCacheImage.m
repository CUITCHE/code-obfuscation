//
//  COCacheImage.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/18.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "COCacheImage.h"
#import "structs.h"
#import "COMethod.h"
#import "global.h"
#import <objc/runtime.h>

FOUNDATION_EXTERN struct __class__ *L_CO_LABEL_CLASS_$;
FOUNDATION_EXTERN struct __image_info _CO_CLASS_IMAGE_INFO_$;

struct __image_info {
    const char *version;
    unsigned long size;
};

NS_INLINE NSUInteger image_size()
{
    return _CO_CLASS_IMAGE_INFO_$.size;
}

NS_INLINE const char * image_ver()
{
    return _CO_CLASS_IMAGE_INFO_$.version;
}

@interface COCacheImage ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<COMethod *> *> *cache;

@end

@implementation COCacheImage

- (instancetype)init
{
    if (self = [super init]) {
        _cache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)searchMethod:(COMethod *)method withSupername:(NSString *)supername
{
    NSArray<COMethod *> *methods = _cache[supername];
    struct __class__ *clazz = NULL;
    if (!methods) {
        methods = [self __cacheWithClassName:supername clazz:&clazz];
        if (!methods) {
            println("\033[41;37m[Error]: %s is not exists in cache image. Check your SDK Version(%s).\033[0m", supername.UTF8String, image_ver());
            exit(-1);
        }
    }
    for (COMethod *m in methods) {
        if ([method isEqual:m]) {
            return YES;
        }
    }
    if (!clazz) {
        return NO;
    }
    return [self searchMethod:method withSupername:@(clazz->name)];
}

- (NSArray<COMethod *> *)__cacheWithClassName:(NSString *)classname clazz:(struct __class__ **)clazz
{
    struct __class__ *p = L_CO_LABEL_CLASS_$;
    struct __class__ *end = p + image_size();
    do {
        if ([classname isEqualToString:@(p->name)]) {
            NSMutableArray<COMethod *> *methods = [NSMutableArray array];
            struct __method__ *p_method = (struct __method__ *)p->method_list->methods;
            for (unsigned int i=0; i<p->method_list->count; ++i) {
                NSString *selector = @(p_method[i].name);
                COMethod *m = [COMethod methodWithName:selector];
                [methods addObject:m];
                NSArray<NSString*> *sels = [selector componentsSeparatedByString:@":"];
                for (NSString *sel in sels) {
                    [m addSelector:[COSelectorPart selectorWithName:sel]];
                }
            }
            [_cache setObject:methods forKey:classname];
            *clazz = p;
            return methods;
        }
    } while (++p < end);
    return nil;
}

- (NSString *)imageVersion
{
    return @(image_ver());
}

@end
