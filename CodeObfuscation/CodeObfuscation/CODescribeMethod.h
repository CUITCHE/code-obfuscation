//
//  CODescribeMethod.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CODescribeSelectorPart.h"
#include <vector>
#include <memory>

using std::vector;
using std::unique_ptr;

@interface CODescribeMethod : NSObject

@end

CO_BEGIN

struct DescribeMethod
{
    NSRange location;
    unique_ptr<vector<DescribeSelectorPart>> selectors;
    NSString *method;

    DescribeMethod(NSString *m, const NSRange &l)
    :method(m)
    ,location(l)
    ,selectors(std::make_unique<vector<DescribeSelectorPart>>())
    {}
};

CO_END
