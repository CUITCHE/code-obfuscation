//
//  COTemplateFile.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COTemplateFile.coh"

@protocol CO_CONFUSION_PROTOCOL COProtocol <NSObject>

@property (nonatomic, strong) id aVar;

- (BOOL)do:(NSString *)task withYou:(id)you and:(id)someWho;

@end

@interface CO_CONFUSION_CLASS COTemplateFile : NSObject

@property (nonatomic, strong) NSString * CO_CONFUSION_PROPERTY prop1;
@property CGFloat CO_CONFUSION_PROPERTY prop2;

CO_CONFUSION_METHOD
- (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2;

CO_CONFUSION_METHOD
- (instancetype)initWithArg1:(CGFloat)arg, ...;

@end

@interface COTemplateFile (CO_CONFUSION_CATEGORY oxxxxo)

@property (nonatomic) CGFloat CO_CONFUSION_PROPERTY prop3;

@end

@interface NSString (CO_CONFUSION_CATEGORY abcde)

CO_CONFUSION_METHOD
- (void)test:(CGFloat)arg;

@end
