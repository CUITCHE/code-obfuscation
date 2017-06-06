//
//  errorCode.h
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/5/31.
//  Copyright © 2017年 CHE. All rights reserved.
//

#ifndef errorCode_h
#define errorCode_h

@import Foundation;

typedef NS_ENUM(NSUInteger, COErrorCode) {
    COErrorCodeFilePathIsNotExist = 1,
    COErrorCodeFileTypeError,
    COErrorCodeOther,
};

#endif /* errorCode_h */
