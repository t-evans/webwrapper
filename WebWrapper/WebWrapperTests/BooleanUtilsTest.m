//
//  BooleanUtilsTest.m
//  WebWrapper
//
//  Created by Troy Evans on 1/7/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BooleanUtils.h"

@interface BooleanUtilsTest : XCTestCase

@end

@implementation BooleanUtilsTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testBooleanValueFromNil
{
    XCTAssertFalse([BooleanUtils booleanValue:nil], @"");
}

- (void)testBooleanValueFromNumber
{
    XCTAssertTrue([BooleanUtils booleanValue:@1], @"");
    XCTAssertFalse([BooleanUtils booleanValue:@5], @"");
    XCTAssertFalse([BooleanUtils booleanValue:@0], @"");
}

- (void)testBooleanValueFromString
{
    XCTAssertTrue([BooleanUtils booleanValue:@"yes"], @"");
    XCTAssertTrue([BooleanUtils booleanValue:@"Yes"], @"");
    XCTAssertTrue([BooleanUtils booleanValue:@"y"], @"");
    XCTAssertTrue([BooleanUtils booleanValue:@"TRUE"], @"");
    XCTAssertTrue([BooleanUtils booleanValue:@"true"], @"");
    XCTAssertFalse([BooleanUtils booleanValue:@"no"], @"");
    XCTAssertFalse([BooleanUtils booleanValue:@"false"], @"");
    XCTAssertFalse([BooleanUtils booleanValue:@""], @"");
    XCTAssertFalse([BooleanUtils booleanValue:@"random string"], @"");
}

@end
