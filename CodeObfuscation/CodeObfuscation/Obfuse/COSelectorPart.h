//
//  COSelectorPart.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class COMethod;

@interface COSelectorPart : NSObject

@property (nonatomic, strong, readonly) COMethod *super;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, readonly) NSRange location;

+ (instancetype)selectorWithName:(NSString *)name location:(NSRange)location;
+ (instancetype)selectorWithName:(NSString *)name;

- (void)setSuper:(COMethod *)superMethod;

@property (nonatomic, strong) NSString *fakename;

@end
