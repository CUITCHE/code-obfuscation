//
//  COCacheImage.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/18.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "CacheImage.h"
#import "structs.h"
#import "obfuse_code-Swift.h"
#include <atomic>

using namespace std;

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

@interface CacheImage ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<Function *> *> *cache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, COCPointer *> *image_hash;

@end

@implementation CacheImage

- (instancetype)init
{
    if (self = [super init]) {
        _cache = [NSMutableDictionary dictionary];
        _image_hash = [NSMutableDictionary dictionary];
        [self _read_image];
    }
    return self;
}

- (BOOL)searchFunction:(Function *)method withSuperName:(NSString *)supername
{
    NSArray<Function *> *methods = _cache[supername];
    struct __class__ *clazz = NULL;
    if (!methods) {
        methods = [self __cacheWithClassName:supername clazz:&clazz];
        if (!methods) {
            fprintf(stderr, "\033[41;37m[Error]: %s is not exists in cache image. Check your SDK Version(%s).\033[0m", supername.UTF8String, image_ver());
            exit(-1);
        }
    }
    for (Function *m in methods) {
        if ([method isEqual:m]) {
            return YES;
        }
    }
    if (!clazz) {
        return NO;
    }
    return [self searchFunction:method withSuperName:@(clazz->name)];
}

- (nullable NSString *)getSuperNameWithClassname:(NSString *)classname
{
    COCPointer *obj = _image_hash[classname];
    return obj.val->superclass->name ? @(obj.val->superclass->name) : nil;
}

- (nullable NSArray<Function *> *)__cacheWithClassName:(NSString *)classname clazz:(struct __class__ **)clazz
{
    COCPointer *obj = _image_hash[classname];
    if (!obj) {
        return nil;
    }

    auto p = obj.val;
    NSMutableArray<Function *> *methods = [NSMutableArray array];
    struct __method__ *p_method = (struct __method__ *)p->method_list->methods;
    for (unsigned int i=0; i<p->method_list->count; ++i) {
        NSString *selector = @(p_method[i].name);
        Function *m = [[Function alloc] initWithName:selector location:NSMakeRange(0, 0)];
        [methods addObject:m];
        NSArray<NSString*> *sels = [selector componentsSeparatedByString:@":"];
        for (NSString *sel in sels) {
            if (sel.length) {
                [m addWithSelector:[[SelectorPart alloc] initWithName:sel location:NSMakeRange(0, 0)]];
            }
        }
    }
    if (clazz) {
        *clazz = p;
        [_cache setObject:methods forKey:classname];
    }
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

+ (NSString *)versionString
{
    return @(image_ver());
}

- (void)enumerateCacheWithBlock:(BOOL(^)(NSString *clazz, NSArray<Function *> *method, NSInteger progress))block
{
    static atomic_long idx;
    idx = 0;
    double total = self.image_hash.count;
    NSUInteger count = self.image_hash.count / 4;
    NSArray<COCPointer *> *objects = self.image_hash.allValues;
    NSArray<COCPointer *> *_1 = [objects subarrayWithRange:NSMakeRange(0, count)];
    NSArray<COCPointer *> *_2 = [objects subarrayWithRange:NSMakeRange(count, count)];
    NSArray<COCPointer *> *_3 = [objects subarrayWithRange:NSMakeRange(2 * count, count)];
    NSArray<COCPointer *> *_4 = [objects subarrayWithRange:NSMakeRange(3 * count, self.image_hash.count - 3 * count)];

    NSArray *pool = @[_1, _2, _3, _4];

    void(^threadBlock)(NSUInteger index) = ^(NSUInteger index){
        for (COCPointer *obj in pool[index]) {
            NSArray<Function *> *methods = [self __cacheWithClassName:@(obj.val->name) clazz:nil];
            if (methods != nil) {
                if (block(@(obj.val->name), methods, (++idx / total) * 100)) {
                    break;
                }
            }
        }
    };

    [NSThread detachNewThreadWithBlock:^{ threadBlock(0); }];
    [NSThread detachNewThreadWithBlock:^{ threadBlock(1); }];
    [NSThread detachNewThreadWithBlock:^{ threadBlock(2); }];
    [NSThread detachNewThreadWithBlock:^{ threadBlock(3); }];
}
@end
