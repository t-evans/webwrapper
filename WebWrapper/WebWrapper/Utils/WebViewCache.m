//
//  ViewCache.m
//  WebWrapper
//
//  Created by Troy Evans on 12/31/13.
//  Copyright (c) 2013 Nutrislice. All rights reserved.
//

#import "WebViewCache.h"

@implementation WebViewCache

static NSMutableDictionary *cachedWebViews;
static NSString *_lock = @"lock";
+ (UIWebView *)getCachedWebViewForUrl:(NSString *)url {
    return [WebViewCache getCachedWebViewForUrl:url loadUrlNow:YES];
}
+ (UIWebView *)getCachedWebViewForUrl:(NSString *)url loadUrlNow:(BOOL)loadUrlNow {
    @synchronized(_lock) {
        if (cachedWebViews == nil)
            cachedWebViews = [[NSMutableDictionary alloc] init];
        UIWebView *webView = cachedWebViews[url];
        if (webView == nil) {
            webView = [[UIWebView alloc] init];
            cachedWebViews[url] = webView;
            webView.backgroundColor = [UIColor whiteColor];
            webView.scalesPageToFit = YES;
            webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin);
            
            //webView.restorationIdentifier = url; // Need to implement encodeRestorableStateWithCoder: and decodeRestorableStateWithCoder in order to use this.
            
            if (loadUrlNow)
                [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60*60]]; // Caches the page for 1 hour
        }
        return webView;
    }
}

static NSMutableDictionary *cachedPropertiesForURL;
+ (BOOL)getBoolPropertyForUrl:(NSString *)url propertyName:(NSString *)propertyName valueToCacheIfNil:(BOOL)valueToCacheIfNil {
    if (cachedPropertiesForURL == nil)
        cachedPropertiesForURL = [[NSMutableDictionary alloc] init];
    NSString *key = [NSString stringWithFormat:@"%@-%@", url, propertyName];
    NSNumber *valueForUrl = (NSNumber *)cachedPropertiesForURL[key];
    if (valueForUrl == nil) {
        valueForUrl = [NSNumber numberWithBool:valueToCacheIfNil];
        cachedPropertiesForURL[key] = valueForUrl;
    }
    return [valueForUrl boolValue];
}

+ (void)removeCachedWebViewForUrl:(NSString *)url {
    if (cachedWebViews != nil) {
        [cachedWebViews removeObjectForKey:url];
    }
}

/*
 * Useful when trying to free up memory
 */
+ (void)removeAllCachedWebViewsNotUsingUrl:(NSString *)url {
    @synchronized(_lock) {
        if (cachedWebViews != nil) {
            NSMutableArray *urlsToRemove = [[NSMutableArray alloc] init];
            for (NSString *key in [cachedWebViews allKeys]) {
                if (![key isEqualToString:url])
                    [urlsToRemove addObject:key];
            }
            [cachedWebViews removeObjectsForKeys:urlsToRemove];
        }
    }
}
@end
