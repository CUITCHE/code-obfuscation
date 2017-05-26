//
//  CodeObfuscationTests.m
//  CodeObfuscationTests
//
//  Created by hejunqiu on 2017/5/26.
//  Copyright © 2017年 CHE. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "COFileAnalysis.h"
#import "DescribeClass.h"

using namespace coob;

@interface CodeObfuscationTests : XCTestCase

@end

@implementation CodeObfuscationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    COFileAnalysis *obj = [COFileAnalysis new];
    NSString *testCode = @"@property (nonatomic, strong) NSString * CO_CONFUSION_PROPERTY prop1;\
    CO_CONFUSION_METHOD\n  \
    - (void)   \n   makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2 :(NSString *)arg3   ;";
    DescribeClass file;
    [obj analysisFileWithString:testCode intoClassObject:file];
}

@end
