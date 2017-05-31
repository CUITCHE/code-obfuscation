//
//  COTemplateFile.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COTemplateFile.coh"

@interface CO_CONFUSION_CLASS COTemplateFile : NSObject

@property (nonatomic, strong) NSString * CO_CONFUSION_PROPERTY prop1;
@property CGFloat CO_CONFUSION_PROPERTY prop2;

CO_CONFUSION_METHOD
- (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2;

CO_CONFUSION_METHOD
- (instancetype)initWithArg1:(CGFloat)arg, ...;

@end
