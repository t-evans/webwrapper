//
//  ValidateWebViewPredicate.m
//  WebWrapper
//
//  Created by Troy Evans on 1/9/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import "WebViewReadyForNavItemPredicate.h"
#import "BooleanUtils.h"
#import "NavigationItem.h"

@implementation WebViewReadyForNavItemPredicate

UIWebView *_webView;
-(id)initWithWebView:(UIWebView *)webView {
    _webView = webView;
    return self;
}

-(BOOL)evaluateWithObject:(id)object {
    if (_webView == nil)
        return YES;
    NavigationItem *navigationItem = (NavigationItem*)object;
    NSString *jsThatMustReturnTrue = [navigationItem jsThatMustBeTrueBeforeFiringEvent];
    if (jsThatMustReturnTrue == nil)
        return YES;
    else {
        NSString *result = [_webView stringByEvaluatingJavaScriptFromString:jsThatMustReturnTrue];
        return [BooleanUtils booleanValue:result];
    }
}

@end
