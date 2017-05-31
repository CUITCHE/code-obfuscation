//
//  CODescribeProperty.m
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "CODescribeProperty.h"

@interface CODescribeProperty ()

@property (nonatomic, strong) NSString *name;
@property (nonatomic) NSRange location;

@end

@implementation CODescribeProperty

+ (instancetype)propertyWithName:(NSString *)name location:(NSRange)location
{
    CODescribeProperty *obj = [CODescribeProperty new];
    obj.name = name;
    obj.location = location;
    return obj;
}

@end
