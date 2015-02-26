//
//  UIColor+Helper.m
//  WebWrapper
//
//  Created by Troy Evans on 1/6/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import "UIColor+Helper.h"

@implementation UIColor (Helper)
+ (UIColor *)colorWithRGBA:(NSUInteger)color
{
    return [UIColor colorWithRed:((color >> 24) & 0xFF) / 255.0f
                           green:((color >> 16) & 0xFF) / 255.0f
                            blue:((color >> 8) & 0xFF) / 255.0f
                           alpha:((color) & 0xFF) / 255.0f];
}
@end
