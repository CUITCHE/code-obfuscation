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

typedef NS_ENUM(int, COErrorCode) {
    COErrorCodeSuccess = 0,
    COErrorCodeFilePathIsNotExist = 1,
    COErrorCodeFileTypeError = 2,
    COErrorCodeCommandParameters = 3,
    COErrorCodeCommandId = 4,
    COErrorCodeCommandOffset = 5,
    COErrorCodeCommandRoot = 6,
    COErrorCodeCommandRelease = 7,
    COErrorCodeCommandDebug = 8,
    COErrorCodeCommandDb = 9,
    COErrorCodeCommandUnknown = 10,
    COErrorCodeOther,
};

#endif /* errorCode_h */
