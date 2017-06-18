//
//  COCacheImage.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/18.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class COMethod;

@interface COCacheImage : NSObject

- (BOOL)searchMethod:(COMethod *)method withSupername:(NSString *)supername;

@property (nonatomic, strong, readonly) NSString *imageVersion;

@end
