//
//  NavigationItem.m
//  WebWrapper
//
//  Created by Troy Evans on 4/22/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import "NavigationItem.h"
#import "BooleanUtils.h"
#import "AppSettings.h"

@implementation NavigationItem
- (id)initWithDictionary:(NSDictionary *)dict {
    if (self)
        self.dict = dict;
    return self;
}

- (BOOL) isHome {
    return [BooleanUtils booleanValue:self.dict[@"isHome"]];
}
- (NSString *) navItemId {
    return self.dict[@"id"];
}
- (NSString *) label {
    return self.dict[@"label"];
}
- (UIImage *) image {
    NSString *imageName = self.dict[@"image"];
    if (imageName == nil)
        return nil;
    else
        return [UIImage imageNamed:imageName];
}
- (NSString *) fontAwesomeIcon {
    return self.dict[@"fontAwesomeIcon"];
}
- (int) fontAwesomeIconSize {
    NSNumber *sizeNumber = (NSNumber *)self.dict[@"fontAwesomeIconSize"];
    int size;
    if (sizeNumber == nil)
        size = 24;
    else
        size = [sizeNumber intValue];
    return size;
}
- (NSString *) url {
    NSString *url = self.dict[@"url"];
    if ([@"dynamic" isEqualToString:url]) {
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        
        NSDictionary *dynamicUrlDescriptor = self.dict[@"dynamicUrlDescriptor"];
        if (dynamicUrlDescriptor == nil) {
            [NSException raise:@"IMPROPERLY CONFIGURED" format:@"If the \"url\" property of the navigation item with label \"%@\" is set to \"dynamic\", then \"dynamicUrlDescriptor\" must also be provided.", [self label]];
        }
        NSString *appPrefId = [dynamicUrlDescriptor valueForKey:@"appPrefId"];
        NSString *urlValueStoredInAppPrefs = [userDefaults stringForKey:appPrefId];
        
        if (urlValueStoredInAppPrefs == nil || [@"" isEqualToString:urlValueStoredInAppPrefs]) {
            NSString *defaultPrefValue = [dynamicUrlDescriptor valueForKey:@"defaultValue"];
            if (defaultPrefValue != nil)
                url = defaultPrefValue;
        }
        else
            url = [AppSettings getUrlAliasForKey:urlValueStoredInAppPrefs defaultValue:urlValueStoredInAppPrefs];
    }
    return url;
}
- (NavigationItem *) navItemToShowForMissingUrl {
    NSString *url = [self url];
    if([@"dynamic" isEqualToString:url]) {
        NSDictionary *dynamicUrlDescriptor = self.dict[@"dynamicUrlDescriptor"];
        if (dynamicUrlDescriptor == nil) {
            [NSException raise:@"IMPROPERLY CONFIGURED" format:@"If the \"url\" property of the navigation item with label \"%@\" is set to \"dynamic\", then \"dynamicUrlDescriptor\" must also be provided.", [self label]];
        }
        NSString *idOfNavItemToShowIfBlank = [dynamicUrlDescriptor valueForKey:@"idOfNavItemToShowIfBlank"];
        NavigationItem *replacementNavItem = [AppSettings getNavigationItemWithId:idOfNavItemToShowIfBlank];
        return replacementNavItem;
    }
    else
        return nil;
}
- (BOOL) hideWebviewToolbar {
    return [BooleanUtils booleanValue:self.dict[@"hideWebviewToolbar"]];
}
- (NSString *) jsThatMustReturnTrueToShow {
    return self.dict[@"jsThatMustReturnTrueToShow"];
}
- (NSString *) eventToFireOnLoad {
    return self.dict[@"eventToFireOnLoad"];
}
- (NSString *) jsThatMustBeTrueBeforeFiringEvent {
    return self.dict[@"jsThatMustBeTrueBeforeFiringEvent"];
}
- (BOOL) isButtonType {
    return [BooleanUtils booleanValue:self.dict[@"isButtonType"]];
}
- (BOOL) needsUserLocation {
    return [BooleanUtils booleanValue:self.dict[@"needsUserLocation"]];
}
- (NSString *) serverUnreachableMsg {
    return self.dict[@"serverUnreachableMsg"];
}
@end
