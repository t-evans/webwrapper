//
//  AppSettings.m
//  WebWrapper
//
//  Created by Troy Evans on 12/30/13.
//  Copyright (c) 2013 Nutrislice. All rights reserved.
//

#import "AppSettings.h"
#import "NSString+UrlUtils.h"
#import "NavigationItem.h"
#import "BooleanUtils.h"


@implementation AppSettings

+ (NavigationItem *)_getNavItemWithId:(NSString *)idToFind navigationItems:(NSArray *)navigationItems {
    if (idToFind == nil)
        return nil;
    for (NavigationItem *navItem in navigationItems) {
        NSString *navItemId = [navItem navItemId];
        if (navItemId == nil || [navItemId length] == 0)
            continue;
        if ([navItemId isEqualToString:idToFind])
            return navItem;
    }
    return nil;
}

+ (NSMutableArray *)_convertToNavItemObjects:(NSArray *)navigationItems
{
    NSMutableArray *navItemObjects = [[NSMutableArray alloc] init];
    for (NSDictionary *immutableNavItem in navigationItems) {
        NavigationItem *navItemObject = [[NavigationItem alloc]initWithDictionary:immutableNavItem];
        [navItemObjects addObject:navItemObject];
    }
    return navItemObjects;
}

+ (NSObject *)getSetting:(NSString *)settingName
{
    static NSMutableDictionary *settings = nil;
    if (settings == nil) {
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:[[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"]];
        settings = (NSMutableDictionary *)[NSPropertyListSerialization propertyListFromData:plistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
        
        NSData *overridesPlistXML = [[NSFileManager defaultManager] contentsAtPath:[[NSBundle mainBundle] pathForResource:@"settings-overrides" ofType:@"plist"]];
        NSDictionary *settingsOverrides = (NSMutableDictionary *)[NSPropertyListSerialization propertyListFromData:overridesPlistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
        
        [settings addEntriesFromDictionary:settingsOverrides];
        
        NSArray *navigationItems = [settings valueForKey:@"navigationItems"];
        NSArray *navItemObjects = [AppSettings _convertToNavItemObjects:navigationItems];
        [settings setObject:navItemObjects forKey:@"navigationItems"];
    }
    return [settings valueForKey:settingName];
}

+ (BOOL)getBooleanSetting:(NSString *)settingName
{
    return [BooleanUtils booleanValue:[AppSettings getSetting:settingName]];
}

static NSArray *navigationItems;
+ (NSArray *)navigationItems {
    if (navigationItems == nil)
        navigationItems = (NSArray *)[AppSettings getSetting:@"navigationItems"];
    return navigationItems;
}
+ (NavigationItem *)getNavigationItemForUrl:(NSString *)url {
    if (url == nil || [url length] == 0)
        return nil;
    NSString *urlWithoutQuerystring = [url urlStringByRemovingAllQuerystringParams];
    
    NSArray *navigationItems = [AppSettings navigationItems];
    for (NavigationItem *navItem in navigationItems) {
        NSString *navItemUrl = [navItem url];
        if (navItemUrl == nil || [navItemUrl length] == 0)
            continue;
        NSString *navItemUrlWithoutQuerystring = [navItemUrl urlStringByRemovingAllQuerystringParams];
        if ([urlWithoutQuerystring isEqualToString:navItemUrlWithoutQuerystring])
            return navItem;
    }
    return nil;
}
+ (NavigationItem *)getNavigationItemWithId:(NSString *)idToFind {
    NSArray *navigationItems = [AppSettings navigationItems];
    return [self _getNavItemWithId:idToFind navigationItems:navigationItems];
}

static NSMutableArray *_cacheableUrlPatterns;
+ (NSArray *)cacheableUrlPatterns {
    if (_cacheableUrlPatterns == nil) {
        NSArray *cacheableUrlPatterns = (NSArray *)[AppSettings getSetting:@"cacheableUrlPatterns"];
        if (cacheableUrlPatterns != nil && [cacheableUrlPatterns count] > 0) {
            _cacheableUrlPatterns = [[NSMutableArray alloc] init];
            for (NSString *pattern in cacheableUrlPatterns) {
                [_cacheableUrlPatterns addObject:[NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil]];
            }
        }
    }
    return _cacheableUrlPatterns;
}

+ (BOOL)isCacheableRequest:(NSURLRequest *)request {
    if (request == nil)
        return NO;
    NSString *method = [request HTTPMethod];
    if (![method isEqualToString:@"GET"])
        return NO;
    NSURL *url = [request URL];
    if (url == nil)
        return NO;
    return [AppSettings isCacheableUrlStr:[url absoluteString]];
}

+ (BOOL)isCacheableUrlStr:(NSString *)url {
    if (url == nil)
        return NO;
    
    NSArray *cacheableUrlPatterns = [AppSettings cacheableUrlPatterns];
    if (cacheableUrlPatterns == nil || [cacheableUrlPatterns count] == 0)
        return YES;
    
    BOOL isCacheable = NO;
    for (NSRegularExpression *pattern in cacheableUrlPatterns) {
        NSTextCheckingResult *match = [pattern firstMatchInString:url options:0 range:NSMakeRange(0, [url length])];
        isCacheable = match != nil;
        if (isCacheable)
            break;
    }
    if (!isCacheable)
        NSLog(@"NOT cacheable URL: \"%@\"", url);
    return isCacheable;
}


static NSDictionary *urlAliases;
+ (NSDictionary *)urlAliases {
    if (urlAliases == nil)
        urlAliases = (NSDictionary *)[AppSettings getSetting:@"urlAliases"];
    return urlAliases;
}
+ (NSString *)getUrlAliasForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    NSDictionary *urlAliases = [AppSettings urlAliases];
    NSString *alias = [urlAliases valueForKey:key];
    if (alias == nil) {
        if ([key hasPrefix:@"http"]) {
            // If the key is, itself, a url, then it obviously isn't one that the default alias is applicable to.
            alias = defaultValue;
        }
        else {
            NSString *defaultAlias = [urlAliases valueForKey:@"default"];
            if (defaultAlias != nil)
                alias = [defaultAlias stringByReplacingOccurrencesOfString:@"-insertAliasKeyHere-" withString:key];
            if (alias == nil)
                alias = defaultValue;
        }
    }
    return alias;
    
}

@end
