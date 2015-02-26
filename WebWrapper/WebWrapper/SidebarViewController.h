//
//  SidebarViewController.h
//  SidebarDemo
//
//  Created by Simon on 29/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebViewController.h"
@class NavigationItem;

@interface SidebarViewController : UITableViewController // We're extending UITableViewController so that we can get the pull-to-refresh thing for free.  We're not using the table view itself, though it does seem to require one to exist.
- (NavigationItem *)homeNavigationItem;
- (NavigationItem *)selectedNavigationItem;
- (BOOL)currentNavItemUrlMatchesHomeUrl;
- (BOOL)prepareWebView:(WebViewController *)webViewController withNavigationItem:(NavigationItem *)navigationItem;
- (void) loadNavigationItem: (NavigationItem *) navigationItem;
- (void) loadNavigationItemAnimated: (NavigationItem *) navigationItem;
@property (nonatomic, strong) NSArray *_visibleNavigationItems;
@end
