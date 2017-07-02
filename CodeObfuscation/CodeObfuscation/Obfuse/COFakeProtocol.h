//
//  COFakeProtocol.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/7/2.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol COFakeProtocol <NSObject>

@property (nonatomic, strong) NSString *fakename;
@property (nonatomic, strong, readonly) NSString *oriname;

@end
