//
//  COProperty.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/25.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COFakeProtocol.h"

@interface COProperty : NSObject<COFakeProtocol>

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, readonly) NSRange location;

+ (instancetype)propertyWithName:(NSString *)name location:(NSRange)location;

@property (nonatomic, strong) NSString *fakename;
@property (nonatomic, strong, readonly) NSString *oriname;

@end
