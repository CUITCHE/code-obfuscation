//
//  COMethod.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COSelectorPart.h"

@interface COMethod : NSObject

@property (nonatomic, strong, readonly) NSString *method;
@property (nonatomic, readonly) NSRange location;
@property (nonatomic, strong, readonly) NSArray<COSelectorPart *> *selectors;

+ (instancetype)methodWithName:(NSString *)methodName location:(NSRange)location;
+ (instancetype)methodWithName:(NSString *)methodName;

- (void)addSelector:(COSelectorPart *)selector;

- (BOOL)equalSelectorsTo:(COMethod *)other;

- (void)fakeWithAnotherMethod:(COMethod *)another;

@end
