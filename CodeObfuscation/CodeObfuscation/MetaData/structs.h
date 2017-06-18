//
//  structs.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/18.
//  Copyright © 2017年 CHE. All rights reserved.
//

#ifndef structs_h
#define structs_h

struct __method__
{
    const char *name;
};

struct __method__list
{
    unsigned int reserved;
    unsigned int count;
    struct __method__ methods[0];
};

struct __class__
{
    struct __class__ *superclass;
    const char *name;
    const struct __method__list *method_list;
};

#endif /* structs_h */
