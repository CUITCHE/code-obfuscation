//
//  COObfuscationDatabase.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/1.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import "AbstractDatabase.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, COObfuscationType) {
    COObfuscationTypeClass,
    COObfuscationTypeCategory,
    COObfuscationTypeProperty,
    COObfuscationTypeMethod,
};

typedef BOOL(^COEnumerator)(NSString *real, NSString *fake,  NSString* _Nullable  location);

@interface COObfuscationDatabase : AbstractDatabase

@end

NS_ASSUME_NONNULL_END
