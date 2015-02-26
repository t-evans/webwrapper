//
//  ValidateWebViewPredicate.h
//  WebWrapper
//
//  Created by Troy Evans on 1/9/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebViewReadyForNavItemPredicate : NSPredicate
-(id)initWithWebView:(UIWebView *)webView;
@end
