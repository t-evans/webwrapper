//
//  NavigationItem.h
//  WebWrapper
//
//  Created by Troy Evans on 4/22/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NavigationItem : NSObject
@property (nonatomic, strong) NSDictionary *dict;
- (id)initWithDictionary:(NSDictionary *)dict;
- (BOOL) isHome;
- (NSString *) navItemId;
- (NSString *) label;
- (UIImage *) image;
- (NSString *) fontAwesomeIcon;
- (int) fontAwesomeIconSize;
- (NSString *) url;
- (NavigationItem *) navItemToShowForMissingUrl;
- (BOOL) hideWebviewToolbar;
- (NSString *) jsThatMustReturnTrueToShow;
- (NSString *) eventToFireOnLoad;
- (NSString *) jsThatMustBeTrueBeforeFiringEvent;
- (BOOL) isButtonType;
- (BOOL) needsUserLocation;
- (NSString *) serverUnreachableMsg;
@end
