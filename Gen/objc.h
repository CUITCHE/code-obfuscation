//
//  objc.h
//  Gen
//
//  Created by hejunqiu on 2017/8/28.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Function;

NS_ASSUME_NONNULL_BEGIN

NSDictionary<NSString *, NSArray<Function *> *>* EnumerateObjectiveClass();

NS_ASSUME_NONNULL_END
