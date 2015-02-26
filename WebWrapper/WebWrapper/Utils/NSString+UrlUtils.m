//
//  NSString+UrlUtils.m
//  WebWrapper
//
//  Created by Troy Evans on 1/9/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import "NSString+UrlUtils.h"

@implementation NSString (UrlUtils)
- (NSURL *)urlByRemovingQuerystringParam:(NSString *)urlParam
{
    NSString *urlString = [self urlStringByRemovingQuerystringParam:urlParam];
    
    // I don't know if there was a specific reason why I was once using stringByAddingPercentEscapesUsingEncoding,
    // but it causes problems if/when the provided url is already encoded, and DOESN'T seem to case problems
    // if when the provided url ISN'T encoded.  Setting it aside for now...
    // NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

- (NSString *)urlStringByRemovingQuerystringParam:(NSString *)urlParam
{
    NSString *pattern = [NSString stringWithFormat:@"[?&]%@=.[^&]+", urlParam];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, [self length]) withTemplate:@""];
    return modifiedString;
}

- (NSString *)urlStringByRemovingAllQuerystringParams
{
    NSRange range = [self rangeOfString:@"?"];
    if (range.length == 0)
        return self;
    else
        return [self substringToIndex:range.location];
}
@end
