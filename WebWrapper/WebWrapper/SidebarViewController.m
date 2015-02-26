//
//  SidebarViewController.m
//  SidebarDemo
//
//  Created by Simon on 29/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "SidebarViewController.h"
#import "SWRevealViewController.h"
#import "WebViewController.h"
#import "AppSettings.h"
#import "TableViewCell.h"
#import "UIColor+Helper.h"
#import "BooleanUtils.h"
#import "WebViewCache.h"
#import "NavigationItem.h"
#import "NSString+FontAwesome.h"

@interface ValidMenuItemPredicate: NSPredicate
-(id)initWithWebView:(UIWebView *)webView;
@end

@implementation ValidMenuItemPredicate
UIWebView *_webView;
-(id)initWithWebView:(UIWebView *)webView {
    _webView = webView;
    return self;
}
-(BOOL)evaluateWithObject:(id)object {
    if (_webView == nil)
        return YES;
    NavigationItem *navigationItem = (NavigationItem*)object;
    NSString *navItemUrl = [navigationItem url];
    if (navItemUrl == nil || [@"" isEqualToString:navItemUrl])
        return NO;
    if ([@"dynamic" isEqualToString:navItemUrl]) {
        NavigationItem *replacementNavItem = [navigationItem navItemToShowForMissingUrl];
        if (replacementNavItem == nil)
            return NO;
    }
    NSString *jsThatMustReturnTrue = [navigationItem jsThatMustReturnTrueToShow];
    if (jsThatMustReturnTrue == nil)
        return YES;
    else {
        NSString *result = [_webView stringByEvaluatingJavaScriptFromString:jsThatMustReturnTrue];
        return [BooleanUtils booleanValue:result];
    }
}
@end

@interface SidebarViewController ()

@property (nonatomic, strong) NSArray *navigationItems;
@property (nonatomic, strong) NavigationItem *latestSelectedNavItem;
@end

@implementation SidebarViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
    self.tableView.backgroundColor = [UIColor colorWithRGBA:0x2b333dff];
    self.tableView.separatorColor = [UIColor colorWithRGBA:0x36404cff];
    self.revealViewController.delegate = self;
    
    // Make it so a swipe-left gesture (anywhere) will hide the sidebar menu.
//    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];  // This doesn't work because it the panGentureRecognizer gets hijaced by the web view (gesture recognizers can only be tied to one UIView at a time)
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [gesture setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:gesture];
    
    self.navigationItems = (NSArray *)[AppSettings getSetting:@"navigationItems"];
}
- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    [self.revealViewController revealToggle:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSArray *)visibleNavigationItems {
    if (self._visibleNavigationItems == nil) {
        NSArray *navigationItems = [self navigationItems];
        NSString *firstNonBlankUrl = nil;
        for (NavigationItem *navItem in navigationItems) {
            NSString *url = [navItem url];
            if (url != nil && ![@"" isEqualToString:url] && ![@"dynamic" isEqualToString:url]) {
                firstNonBlankUrl = url;
                break;
            }
        }
        UIWebView *firstDisplayableWebView = [WebViewCache getCachedWebViewForUrl:firstNonBlankUrl];
        NSPredicate *predicate = [[ValidMenuItemPredicate alloc] initWithWebView:firstDisplayableWebView];
        self._visibleNavigationItems = [navigationItems filteredArrayUsingPredicate:predicate];
    }
    return self._visibleNavigationItems;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSArray *visibleNavItems = [self visibleNavigationItems];
    return [visibleNavItems count];
}

- (NavigationItem *)navigationItemAtIndex:(NSIndexPath *)indexPath {
    NavigationItem *navigationItem = [self.visibleNavigationItems objectAtIndex: indexPath.row];
    return navigationItem;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NavigationItem *navigationItem = [self navigationItemAtIndex:indexPath];
    NSString *cellIdentifier = [navigationItem isButtonType] ? @"ButtonCell" : @"NormalCell";
    
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.label.text = [navigationItem label];
    NSString *fontAwesomeIcon = [navigationItem fontAwesomeIcon];
    if (fontAwesomeIcon == nil) {
        UIImage *image = [navigationItem image];
        if (image != nil)
            cell.image.image = image;
    }
    else {
        int fontSize = [navigationItem fontAwesomeIconSize];
        cell.icon.font = [UIFont fontWithName:kFontAwesomeFamilyName size:fontSize];
        cell.icon.text = [NSString fontAwesomeIconStringForIconIdentifier:fontAwesomeIcon];
    }
    
    cell.backgroundColor = [UIColor clearColor]; // For some reason, when running on the ipad this needs to be explicitely set to clear.  Seems to be clear by default when running on the iPhone.
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NavigationItem *navigationItem = [self navigationItemAtIndex:indexPath];
    CGFloat cellHeight = [navigationItem isButtonType] ? 60 : 44;
    return cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer - This eliminates the extra separator lines at the bottom of the sidebar (where there are no links).
    return 0.01f;
}

- (BOOL)prepareWebView:(WebViewController *)webViewController withNavigationItem:(NavigationItem *)navigationItem
{
    BOOL didRedirect = NO;
    NSString *url = [navigationItem url];
    if ([@"dynamic" isEqualToString:url]) {
        NavigationItem *replacementNavItem = [navigationItem navItemToShowForMissingUrl];
        if (replacementNavItem == nil) {
            [NSException raise:@"IMPROPERLY CONFIGURED" format:@"If the \"url\" property of the navigation item with label \"%@\" is set to \"dynamic\", then the \"dynamicUrlDescriptor\" must also be provided and must have a property named \"idOfNavItemToShowIfBlank\".", [navigationItem label]];
        }
        
        didRedirect = YES;
        [self loadNavigationItem:replacementNavItem];
    }
    if (!didRedirect) {
        webViewController.url = [navigationItem url];
        webViewController.hideWebviewToolbar = [navigationItem hideWebviewToolbar];
    }
    return didRedirect;
}

- (NavigationItem *)selectedNavigationItem
{
    // Set the title of navigation bar by using the menu items
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NavigationItem *navigationItem = [self navigationItemAtIndex:indexPath];
    return navigationItem;
}

- (NavigationItem *)homeNavigationItem
{
    for (NavigationItem *navItem in [self visibleNavigationItems]) {
        if ([navItem isHome]) {
            return navItem;
        }
    }
    
    [NSException raise:@"IMPROPERLY CONFIGURED" format:@"At least one navigation item must have \"isHome\" set to True."];
    return nil;
}

- (BOOL)currentNavItemUrlMatchesHomeUrl {
    NSString *currentUrl = [self.selectedNavigationItem url];
    NavigationItem *homeNavigationItem = [self homeNavigationItem];
    NSString *homeUrl = [homeNavigationItem url];
    return [homeUrl isEqualToString:currentUrl];
}

- (BOOL) sidebarIsOpen {
    UIViewController * currentView = [self.revealViewController childViewControllerForStatusBarStyle];
    BOOL sidebarIsOpen = [currentView isKindOfClass:self.class];
    return sidebarIsOpen;
}

- (void) prepareForSegue: (UIStoryboardSegue *) segue sender: (id) sender
{ 
    NavigationItem *navigationItem = [self selectedNavigationItem];
    UINavigationController *destViewController = (UINavigationController*)segue.destinationViewController;
    destViewController.title = [navigationItem label];
    
    if ([destViewController isKindOfClass:[WebViewController class]]) {
        WebViewController *webViewController = (WebViewController *)destViewController;
        BOOL didRedirect = [self prepareWebView:webViewController withNavigationItem:navigationItem];
        if (didRedirect)
            return;
        webViewController.currentNavigationItem = navigationItem;
    }
    self.latestSelectedNavItem = navigationItem;
    
    if ( [segue isKindOfClass: [SWRevealViewControllerSegue class]] ) {
        SWRevealViewControllerSegue *swSegue = (SWRevealViewControllerSegue*) segue;
        
        swSegue.performBlock = ^(SWRevealViewControllerSegue* rvc_segue, UIViewController* svc, UIViewController* dvc) {
            
            UINavigationController* navController = (UINavigationController*)self.revealViewController.frontViewController;
            [navController setViewControllers: @[dvc] animated: NO ];
            
            if ([AppSettings getBooleanSetting:@"openSidebarFullyBeforeClose"] && [self sidebarIsOpen])
                [self.revealViewController setFrontViewPosition: FrontViewPositionRightMost animated: YES];
            [self.revealViewController setFrontViewPosition: FrontViewPositionLeft animated: YES];
        };
        
    }
    
}

- (NSIndexPath *)_indexPathOfNavigationItem:(NavigationItem *)navigationItem
{
    NSInteger navItemIndex = [self.visibleNavigationItems indexOfObject:navigationItem];
    if (navItemIndex == NSNotFound) {
        // Likely means the user clicked on link from a page that has the same URL
        // as a one of the dynamic sidebar items, and that sidebar items isn't
        // showing yet.
        // Rebuilding the sidebar items should do the trick.
        self._visibleNavigationItems = nil;
        [self.tableView reloadData];
    }
    navItemIndex = [self.visibleNavigationItems indexOfObject:navigationItem];
    assert(navItemIndex != NSNotFound);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:navItemIndex inSection:0];
    return indexPath;
}

- (void)_selectNavigationItem:(NavigationItem *)navigationItem
{
    NSIndexPath *indexPath = [self _indexPathOfNavigationItem:navigationItem];
    UITableView *tableView = (UITableView *)[self view];
    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}
- (void)_loadSelectedNavItem
{
    [self performSegueWithIdentifier:@"sidebarItemToWebviewSegue" sender:self];
}
- (void) loadNavigationItem: (NavigationItem *) navigationItem
{
    [self _selectNavigationItem:navigationItem];
    [self _loadSelectedNavItem];
}
- (void) loadNavigationItemAnimated: (NavigationItem *) navigationItem
{
    [self.revealViewController revealToggle:nil];
    
    [self performSelector:@selector(_selectNavigationItem:) withObject:navigationItem afterDelay:0.25f];
    [self performSelector:@selector(_loadSelectedNavItem) withObject:nil afterDelay:0.7f];
}

- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position {
    if (position == FrontViewPositionRight) {
        self._visibleNavigationItems = nil;
        [self.tableView reloadData];
        
        NavigationItem *prevNavItem;
        if (self.latestSelectedNavItem == nil)
            prevNavItem = [self homeNavigationItem];
        else
            prevNavItem = self.latestSelectedNavItem;
        
        if ([AppSettings getBooleanSetting:@"highlightCurrentItemWhenSidebarOpens"])
            [self _selectNavigationItem:prevNavItem];  // Select the current nav item so that it is highlighted when the sidebar opens.
    }
}

@end
