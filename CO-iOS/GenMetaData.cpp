//
//  GenMetaData.cpp
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/18.
//  Copyright © 2017年 CHE. All rights reserved.
//

#include "structs.h"

#ifndef CO_EXPORT
#define CO_EXPORT extern "C"
#endif

/// Meta data for NSObject

static struct /*__method__list_t*/ {
    unsigned int entsize;
    unsigned int method_count;
    struct __method__ method_list[4];
} _CO_METHODNAMES_NSObject_$ __attribute__ ((used, section ("__DATA,__co_const"))) = {
    sizeof(__method__),
    4,
    {{"init"},{"description"},{"responseToSelector:"},{"load"}}
};

CO_EXPORT struct __class__ _CO_CLASS_$_NSObject __attribute__ ((used, section ("__DATA,__co_data"))) = {
    0,
    "NSObject", // name
    (const struct __method__list *)&_CO_METHODNAMES_NSObject_$
};

static struct __class__ *L_CO_LABEL_CLASS_$[1] __attribute__((used, section ("__DATA, __co_classlist"))) = {
    &_CO_CLASS_$_NSObject
};

static struct /*__image_info*/ {
    unsigned int info;
    unsigned int size;
} _CO_CLASS_IMAGE_INFO_$ __attribute__ ((used, section ("__DATA,__co_const"))) = {
    0,
    1
};
