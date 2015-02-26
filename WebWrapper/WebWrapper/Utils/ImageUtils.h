//
//  ImageUtils.h
//  WebWrapper
//
//  Created by Troy Evans on 1/2/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtils : NSObject
+ (UIImage*) cveateImageWithRoundedCornersUsingRect:(CGRect) rect topLeftRadius:(CGFloat) topLeftRadius topRightRadius:(CGFloat) topRightRadius bottomLeftRadius: (CGFloat) bottomLeftRadius bottomRightRadius:(CGFloat) bottomRightRadius;
+ (void) addRoundedCornersToView:(UIView *) view topLeftRadius:(CGFloat) topLeftRadius topRightRadius:(CGFloat) topRightRadius bottomLeftRadius:(CGFloat) bottomLeftRadius bottomRightRadius:(CGFloat) bottomRightRadius;
@end
