//
//  ViewCache.h
//  WebWrapper
//
//  Created by Troy Evans on 12/31/13.
//  Copyright (c) 2013 Nutrislice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebViewCache : NSObject
+ (UIWebView *)getCachedWebViewForUrl:(NSString *)url;
+ (UIWebView *)getCachedWebViewForUrl:(NSString *)url loadUrlNow:(BOOL)loadUrlNow;
+ (void)removeCachedWebViewForUrl:(NSString *)url;
+ (BOOL)getBoolPropertyForUrl:(NSString *)url propertyName:(NSString *)propertyName valueToCacheIfNil:(BOOL)valueToCacheIfNil;
/*
 * Useful when trying to free up memory
 */
+ (void)removeAllCachedWebViewsNotUsingUrl:(NSString *)url;
@end
