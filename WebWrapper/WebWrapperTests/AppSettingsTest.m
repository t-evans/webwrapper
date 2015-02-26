//
//  AppSettingsTest.m
//  WebWrapper
//
//  Created by Troy Evans on 5/15/14.
//  Copyright (c) 2013 Nutrislice. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AppSettings.h"

@interface AppSettingsTest : XCTestCase

@end

@implementation AppSettingsTest

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

- (void)testGetUrlAliasForKey
{
    XCTAssertEqualObjects([AppSettings getUrlAliasForKey:@"staging" defaultValue:@"defaultValue"], @"http://staging.myCompany.com/?isRunningInMobileApp=true");
    XCTAssertEqualObjects([AppSettings getUrlAliasForKey:@"foo" defaultValue:@"defaultValue"], @"http://foo/?isRunningInMobileApp=true");
    XCTAssertEqualObjects([AppSettings getUrlAliasForKey:@"10.0.1.2:8000" defaultValue:@"defaultValue"], @"http://10.0.1.2:8000/?isRunningInMobileApp=true");
    XCTAssertEqualObjects([AppSettings getUrlAliasForKey:@"http://10.0.1.2:8000" defaultValue:@"defaultValue"], @"defaultValue");
}

@end
