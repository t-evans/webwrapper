//
//  AppSettings.h
//  WebWrapper
//
//  Created by Troy Evans on 12/30/13.
//  Copyright (c) 2013 Nutrislice. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NavigationItem;

@interface AppSettings : NSObject
+ (NSString *)getSetting:(NSString *)settingName;
+ (BOOL)getBooleanSetting:(NSString *)settingName;
+ (NSArray *)navigationItems;
+ (NavigationItem *)getNavigationItemForUrl:(NSString *)url;
+ (NavigationItem *)getNavigationItemWithId:(NSString *)idToFind;

/*!
 * Returns true if the provided request is NOT a POST request, and if the url in the
 * request matches one of the regex patterns in the "cacheableUrlPatterns" setting.
 */
+ (BOOL)isCacheableRequest:(NSURL *)request;
+ (NSString *)getUrlAliasForKey:(NSString *)key defaultValue:(NSString *)defaultValue;
@end
