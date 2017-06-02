//
//  _COStringContainer.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/2.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "_COStringContainer.h"

@interface _COStringContainer ()

@property (nonatomic, strong) NSString *content;

@end

@implementation _COStringContainer

+ (instancetype)stringContainer:(NSString *)content
{
    _COStringContainer *obj = [_COStringContainer new];
    obj.content = content;
    return obj;
}

- (NSString *)description
{
    return self.content;
}

- (NSString *)debugDescription
{
    return self.description;
}

@end
