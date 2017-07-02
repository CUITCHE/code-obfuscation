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

FOUNDATION_EXTERN struct __class__ **L_CO_LABEL_CLASS_$;
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

@interface COCPointer : NSObject
@property (nonatomic) struct __class__ *val;
@end

@implementation COCPointer

+ (instancetype)pointer:(struct __class__ *)val
{
    COCPointer *obj = [COCPointer new];
    obj.val = val;
    return obj;
}

@end

@interface COCacheImage ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<COMethod *> *> *cache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, COCPointer *> *image_hash;

@end

@implementation COCacheImage

- (instancetype)init
{
    if (self = [super init]) {
        _cache = [NSMutableDictionary dictionary];
        _image_hash = [NSMutableDictionary dictionary];
        [self _read_image];
    }
    return self;
}

- (BOOL)searchMethod:(COMethod *)method withSuperName:(NSString *)supername
{
    NSArray<COMethod *> *methods = _cache[supername];
    struct __class__ *clazz = NULL;
    if (!methods) {
        methods = [self __cacheWithClassName:supername clazz:&clazz];
        if (!methods) {
            exit_msg(-1, "\033[41;37m[Error]: %s is not exists in cache image. Check your SDK Version(%s).\033[0m", supername.UTF8String, image_ver());
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
    return [self searchMethod:method withSuperName:@(clazz->name)];
}

- (NSString *)getSuperNameWithClassname:(NSString *)classname
{
    COCPointer *obj = _image_hash[classname];
    return obj.val->superclass->name ? @(obj.val->superclass->name) : nil;
}

- (NSArray<COMethod *> *)__cacheWithClassName:(NSString *)classname clazz:(struct __class__ **)clazz
{
    COCPointer *obj = _image_hash[classname];
    if (!obj) {
        return nil;
    }

    auto p = obj.val;
    NSMutableArray<COMethod *> *methods = [NSMutableArray array];
    struct __method__ *p_method = (struct __method__ *)p->method_list->methods;
    for (unsigned int i=0; i<p->method_list->count; ++i) {
        NSString *selector = @(p_method[i].name);
        COMethod *m = [COMethod methodWithName:selector];
        [methods addObject:m];
        NSArray<NSString*> *sels = [selector componentsSeparatedByString:@":"];
        for (NSString *sel in sels) {
            if (sel.length) {
                [m addSelector:[COSelectorPart selectorWithName:sel]];
            }
        }
    }
    [_cache setObject:methods forKey:classname];
    *clazz = p;
    return methods;
}

- (NSString *)imageVersion
{
    return @(image_ver());
}

- (void)_read_image
{
    struct __class__ *p = L_CO_LABEL_CLASS_$[0];
    struct __class__ *end = p + image_size();
    do {
        _image_hash[@(p->name)] = [COCPointer pointer:p];
    } while (++p < end);
}

+ (NSString *)version
{
    return @(image_ver());
}
@end
