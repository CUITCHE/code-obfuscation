//
//  COCacheImage.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/18.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Function;

@interface CacheImage : NSObject

- (BOOL)searchFunction:(Function *)method withSuperName:(NSString *)supername;
- (nullable NSString *)getSuperNameWithClassname:(NSString *)classname;

@property (nonatomic, strong, readonly) NSString *imageVersion;
@property (nonatomic, strong, readonly, class) NSString *versionString;

- (void)enumerateCacheWithBlock:(BOOL(^)(NSString *clazz, NSArray<Function *> *method, NSInteger progress))block;

@end

NS_ASSUME_NONNULL_END
