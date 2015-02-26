//
//  URLUtilsTest.m
//  WebWrapper
//
//  Created by Troy Evans on 4/15/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+UrlUtils.h"

@interface URLUtilsTest : XCTestCase

@end

@implementation URLUtilsTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testUrlStringByRemovingAllQuerystringParams
{
    XCTAssertEqualObjects([@"http://some.domain.com/some/path?param1=foo&param2=bar" urlStringByRemovingAllQuerystringParams], @"http://some.domain.com/some/path");
    XCTAssertEqualObjects([@"http://some.domain.com/some/path" urlStringByRemovingAllQuerystringParams], @"http://some.domain.com/some/path");
}

@end
