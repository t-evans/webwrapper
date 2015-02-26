//
//  BooleanUtils.m
//  WebWrapper
//
//  Created by Troy Evans on 1/7/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import "BooleanUtils.h"

@implementation BooleanUtils
+ (BOOL)booleanValue:(NSObject *)obj {
    BOOL boolValue;
    if (obj == nil)
        boolValue = NO;
    else if ([obj isKindOfClass:[NSNumber class]]) {
        boolValue = [[NSNumber numberWithBool:YES] isEqualToNumber:(NSNumber *)obj];
    }
    else if ([obj isKindOfClass:[NSString class]]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", @[@"yes", @"y", @"true", @"t"]];
        boolValue = [predicate evaluateWithObject:[((NSString *)obj) lowercaseString]];
    }
    else
        boolValue = NO;
    return boolValue;
}
@end
