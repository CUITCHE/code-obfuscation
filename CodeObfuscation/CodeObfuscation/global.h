//
//  global.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#ifndef global_h
#define global_h

#ifndef println
#define println(fmt, ...) fprintf(stderr, fmt, ##__VA_ARGS__); putchar('\n'); fflush(stderr)
#endif

#ifndef exit_msg
#define exit_msg(code, fmt, ...) println(fmt, ##__VA_ARGS__); exit(code)
#endif

FOUNDATION_EXTERN NSString *const __scanTagString__;
FOUNDATION_EXTERN NSString *const __method__;
FOUNDATION_EXTERN NSString *const __property__;
FOUNDATION_EXTERN NSString *const __targetPathExtesion__;

#endif /* global_h */
