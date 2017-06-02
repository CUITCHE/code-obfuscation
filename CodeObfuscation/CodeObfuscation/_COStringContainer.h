//
//  _COStringContainer.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/2.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface _COStringContainer : NSObject

@property (nonatomic, strong, readonly) NSString *content;

+ (instancetype)stringContainer:(NSString *)content;

@end
