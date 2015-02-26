//
//  NUTCachingURLProtocol.m
//  WebWrapper
//
//  Created by Troy Evans on 1/27/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import "NUTRCachingURLProtocol.h"
#import "RNCachingURLProtocol.h"
#import "AppSettings.h"

@implementation NUTRCachingURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([super canInitWithRequest:request]) { // Need to ask the parent class first since it sets a header/flag that it uses to detect/prevent infinite looping.
        return [AppSettings isCacheableRequest:request];
    }
    return NO;
}
@end
