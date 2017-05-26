//
//  CODescribeFile.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CODescribeMethod.h"
#import "CODescribeProperty.h"


CO_BEGIN

struct DescribeClass
{
    const NSString *filePath;

    NSString *className = 0;
    NSString *superName = 0;

    unique_ptr<vector<DescribeProperty>> declProperties;
    unique_ptr<vector<DescribeMethod>> declMethods;

    DescribeClass(NSString *filepath)
    :filePath(filepath)
    ,declProperties(std::make_unique<vector<DescribeProperty>>())
    ,declMethods(std::make_unique<vector<DescribeMethod>>())
    {}
};

CO_END
