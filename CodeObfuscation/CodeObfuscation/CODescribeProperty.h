//
//  CODescribeProperty.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "global.h"

@interface CODescribeProperty : NSObject

@end

CO_BEGIN

struct DescribeProperty
{
    NSString *name;
    NSRange location;
    DescribeProperty(NSString *name, const NSRange &location)
    :name(name)
    ,location(location)
    {}
};

CO_END
