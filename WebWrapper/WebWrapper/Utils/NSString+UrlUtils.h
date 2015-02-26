//
//  NSString+UrlUtils.h
//  WebWrapper
//
//  Created by Troy Evans on 1/9/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (UrlUtils)
- (NSURL *)urlByRemovingQuerystringParam:(NSString *)paramName;
- (NSString *)urlStringByRemovingQuerystringParam:(NSString *)paramName;
- (NSString *)urlStringByRemovingAllQuerystringParams;
@end
