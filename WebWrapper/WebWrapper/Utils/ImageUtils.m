//
//  ImageUtils.m
//  WebWrapper
//
//  Created by Troy Evans on 1/2/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils

+ (UIImage*) cveateImageWithRoundedCornersUsingRect:(CGRect) rect topLeftRadius:(CGFloat) radius_tl topRightRadius:(CGFloat) radius_tr bottomLeftRadius: (CGFloat) radius_bl bottomRightRadius:(CGFloat) radius_br {

    CGContextRef context;
    CGColorSpaceRef colorSpace;

    colorSpace = CGColorSpaceCreateDeviceRGB();

    // create a bitmap graphics context the size of the image
    context = CGBitmapContextCreate( NULL, rect.size.width, rect.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast );

    // free the rgb colorspace
    CGColorSpaceRelease(colorSpace);    

    if ( context == NULL ) {
        return NULL;
    }

    // cerate mask

    CGFloat minx = CGRectGetMinX( rect ), midx = CGRectGetMidX( rect ), maxx = CGRectGetMaxX( rect );
    CGFloat miny = CGRectGetMinY( rect ), midy = CGRectGetMidY( rect ), maxy = CGRectGetMaxY( rect );

    CGContextBeginPath( context );
    CGContextSetGrayFillColor( context, 1.0, 0.0 );
    CGContextAddRect( context, rect );
    CGContextClosePath( context );
    CGContextDrawPath( context, kCGPathFill );

    CGContextSetGrayFillColor( context, 1.0, 1.0 );
    CGContextBeginPath( context );
    CGContextMoveToPoint( context, minx, midy );
    CGContextAddArcToPoint( context, minx, miny, midx, miny, radius_bl );
    CGContextAddArcToPoint( context, maxx, miny, maxx, midy, radius_br );
    CGContextAddArcToPoint( context, maxx, maxy, midx, maxy, radius_tr );
    CGContextAddArcToPoint( context, minx, maxy, minx, midy, radius_tl );
    CGContextClosePath( context );
    CGContextDrawPath( context, kCGPathFill );

    // Create CGImageRef of the main view bitmap content, and then
    // release that bitmap context
    CGImageRef bitmapContext = CGBitmapContextCreateImage( context );
    CGContextRelease( context );

    // convert the finished resized image to a UIImage 
    UIImage *theImage = [UIImage imageWithCGImage:bitmapContext];
    // image is retained by the property setting above, so we can 
    // release the original
    CGImageRelease(bitmapContext);

    // return the image
    return theImage;
}

+ (void) addRoundedCornersToView:(UIView *) view topLeftRadius:(CGFloat) topLeftRadius topRightRadius:(CGFloat) topRightRadius bottomLeftRadius:(CGFloat) bottomLeftRadius bottomRightRadius:(CGFloat) bottomRightRadius {
    UIImage *mask = [ImageUtils cveateImageWithRoundedCornersUsingRect:view.bounds
                                                         topLeftRadius:topLeftRadius
                                                         topRightRadius:topRightRadius
                                                         bottomLeftRadius:bottomLeftRadius
                                                         bottomRightRadius:bottomRightRadius];
    // Create a new layer that will work as a mask
    CALayer *layerMask = [CALayer layer];
    layerMask.frame = view.bounds;
    // Put the mask image as content of the layer
    layerMask.contents = (id)mask.CGImage;       
    // set the mask layer as mask of the view layer
    view.layer.mask = layerMask;
}
@end
