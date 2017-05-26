//
//  CODescribeSelectorPart.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "global.h"

@interface CODescribeSelectorPart : NSObject

@end


CO_BEGIN

struct DescribeMethod;

struct DescribeSelectorPart
{
    DescribeMethod *super = 0;
    NSString *name;
    NSRange location; // location相对于method串

    DescribeSelectorPart(NSString *n, const NSRange &l)
    :name(n)
    ,location(l)
    {}
};

CO_END
