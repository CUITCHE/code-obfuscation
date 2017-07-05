//
//  CO-Features.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/7/5.
//  Copyright © 2017年 CHE. All rights reserved.
//

#ifndef CO_FEATURES_H
#define CO_FEATURES_H

// For make an obfuscation c-string.
// Use @CO_NAME to make a NSString, such as NSClassFromNSString(@CO_NAME(CUSTOME_CLASS)), the 'CUSTOME_CLASS' might have been obfused.
#ifndef CO_NAME
# define ____name____(name) #name
# define CO_NAME(name) ____name____(name)
#endif // !CO_NAME

#ifndef CO_PROPERTY_SET
# define __CO_SET_TYPE__(property, Property, type) - (void)set##Property:(type)property
# define __CO_SET__(property, Property, clazz) __CO_SET_TYPE__(property, Property, __typeof__(((clazz *)0).property))
# if defined(DEBUG)
// For arguments: 1th is your wirtten, 2nd is a text whose first letter is captial, 3rd is a type
#  define CO_PROPERTY_SET(property, Property, clazz) __CO_SET__(property, Property, clazz)
#  define CO_PROPERTY_SET_TYPE(property, Property, type) __CO_SET_TYPE__(property, Property, type)
# else
   // Under Release, property starts with a capital letter.
#  define CO_PROPERTY_SET(property, Property, clazz) __CO_SET__(property, property, clazz)
#  define CO_PROPERTY_SET_TYPE(property, Property, type) __CO_SET_TYPE__(property, property, type)
# endif // defined(DEBUG)
#endif // !CO_PROPERTY_SET

#ifndef CO_PROPERTY_GET
# define __CO_GET_TYPE__(property, type) - (type)property
# define __CO_GET__(property, clazz) __CO_GET_TYPE__(property, __typeof__(((clazz *)0).property))
# define CO_PROPERTY_GET(property, clazz) __CO_GET__(property, clazz)
# define CO_PROPERTY_GET_TYPE(property, type) __CO_GET_TYPE__(property, type)
#endif // !CO_PROPERTY_GET

#ifndef CO_VAR_NAME
# define __CO_P_NAME__(property) _##property
# define CO_VAR_NAME(property) __CO_P_NAME__(property)

// convenience macro if macro `_` is not exist.
# ifndef _
#  define _(property) CO_VAR_NAME(property)
# endif // !_
#endif // !CO_VAR_NAME

#endif /* CO_FEATURES_H */
