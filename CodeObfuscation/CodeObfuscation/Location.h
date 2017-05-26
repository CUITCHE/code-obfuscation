//
//  Location.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#ifndef Location_h
#define Location_h

#import <Foundation/NSRange.h>
#import "global.h"

CO_BEGIN

struct Location
{
    NSRange location;
    NSUInteger line;
    NSUInteger reserved;

    Location(NSRange range, NSUInteger line)
    :location(range)
    ,line(line)
    {}
};

CO_END

#endif /* Location_h */
