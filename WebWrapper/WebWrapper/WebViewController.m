/*
     File: WebViewController.m 
 Abstract: The view controller for hosting the UIWebView feature of this sample. 
  Version: 2.11 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2013 Apple Inc. All Rights Reserved. 
  
  
 2013-12-30 - Modified to hide the address bar, navigation bar, and add 
 iOS7 position compensations
 */

#import "WebViewController.h"
#import "Constants.h"
#import "SWRevealViewController.h"
#import "SidebarViewController.h"
#import "WebViewCache.h"
#import "MBProgressHUD.h"
#import "ImageUtils.h"
#import "AppSettings.h"
#import "Jockey.h"
#import "JockeyjsAlerts.h"
#import "JockeyjsSimpleStorage.h"
#import "BooleanUtils.h"
#import "NSURL+Parameters.h"
#import "NSString+UrlUtils.h"
#import "WebViewReadyForNavItemPredicate.h"
#import "NavigationItem.h"
#import "NSTimer+Blocks.h"

typedef enum
{
    TryAgain,
    KeepWaitingOrCancel

} ButtonIndexes;

@interface WebViewController () <UITextFieldDelegate, UIWebViewDelegate>
@property (nonatomic, strong) UIWebView	*currentWebView;
@property (nonatomic, strong) UIBarButtonItem *backBtn;
@property (nonatomic, strong) UIBarButtonItem *forwardBtn;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) NSMutableArray *selectorsToPerformWhenPageFinisesLoading;
@end


#pragma mark -

@implementation WebViewController
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *oldLocation = locations[0];
    CLLocation *newLocation = [locations lastObject];
    self.currentLocation = newLocation;
    
    [Jockey send:@"updateUserLocation" withPayload:@{
         @"latitude": [NSNumber numberWithDouble:newLocation.coordinate.latitude],
         @"longitude": [NSNumber numberWithDouble:newLocation.coordinate.longitude]
    } toWebView:self.currentWebView];
    
    NSLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
    NSLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    switch ([error code]) {
        case kCLErrorNetwork:
            // Ignore - let it keep trying
            break;
        case kCLErrorDenied:
            [self performSelectorWhenPageFinishesLoading:@selector(_alertWebViewThatLocationAccessIsDenied)];
            break;
        default:
            NSLog(@"Unrecognized network error while attempting to obtain user's location: %@", error);
            // Let it keep trying
            break;
    }
}

typedef void (^TryUntilSucceedsBlock)();
- (void) tryJockeyEventUntilSucceeds:(NSString *)jockeyEventToFire interval:(NSTimeInterval)interval maxAttempts:(int)maxAttempts
{
    TryUntilSucceedsBlock aBlock;
    __block BOOL webViewReceivedEvent = NO;
    __block NSTimer *timer = nil;
    __block int attemptCount = 0;
    aBlock = [^() {
        attemptCount++;
        if (webViewReceivedEvent || attemptCount > maxAttempts) {
            if (timer) {
                [timer invalidate];
                timer = nil;
            }
        }
        else {
            [Jockey send:jockeyEventToFire withPayload:@{} toWebView:self.currentWebView perform:^{
                webViewReceivedEvent = YES;
            }];
        }
    } copy];
    timer = [NSTimer scheduledTimerWithTimeInterval:interval block:aBlock repeats:YES];
}

- (void)_alertWebViewThatLocationAccessIsDenied {
    [self tryJockeyEventUntilSucceeds:@"userLocationAccessDenied" interval:1.0 maxAttempts:10];
}

- (void)performSelectorWhenPageFinishesLoading:(SEL)selector {
    if (self.selectorsToPerformWhenPageFinisesLoading == nil) {
        self.selectorsToPerformWhenPageFinisesLoading = [[NSMutableArray alloc] init];
    }
    [self.selectorsToPerformWhenPageFinisesLoading addObject:[NSValue valueWithPointer:selector]];
    
    if (_pageLoadTimer == nil) {
        // A null timer means the page has finished loading (the fact that this method
        // was called indicates that the page had STARTED loading at some point).
        // Therefore, we should fire the selector now.
        [self _performOnLoadSelectors];
    }
}

- (void)_performOnLoadSelectors {
    if (self.selectorsToPerformWhenPageFinisesLoading != nil) {
        for (NSValue *selectorValue in self.selectorsToPerformWhenPageFinisesLoading) {
            SEL selector = (SEL)[selectorValue pointerValue];
            [self performSelector:selector withObject:nil afterDelay:0.0];
        }
        [self.selectorsToPerformWhenPageFinisesLoading removeAllObjects];
    }
}

- (SidebarViewController *)getSidebarViewController
{
    SidebarViewController *sidebarViewController = (SidebarViewController *)[self.revealViewController rearViewController];
    return sidebarViewController;
}

- (void)addVersionSpecificPositioning:(CGRect *)webFrame
{
    // If using the UITableViewController (which we added to get the pull-to-refresh thing for free), it shifts ios7 down to the correct position, but leaves the view too large (18 pixels).  For ios6, it shifts the view down 18 pixels too far, but it is the correct size.
    // If NOT using the UITableViewController, we need th move the view down 18 pixels and shrink it 18 pixels for ios7. ios6 needs to be shifted up 20 pixels.
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) { // If iOS7 or higher, the content needs to be shifted down to accommodate the phone header.
        //webFrame->origin.y += 18; No shifting needed if using UITableViewController
        webFrame->size.height -= 18;
    }
    else {
        webFrame->origin.y -= 20; // Not sure exactly why ios6 needs this... but it does.
    }
}

- (void)_createWebViewIfNecessaryForUrl:(NSString *)url
{
    UIWebView *webView = [WebViewCache getCachedWebViewForUrl:url];
    CGRect webFrame = self.view.frame;
    [self addVersionSpecificPositioning:&webFrame];
    webView.frame = webFrame;
    webView.delegate = self;
    self.currentWebView = webView;
    [self.view addSubview:webView];
    [self addSliderMenuButtonToView:webView];
    if (self.hideWebviewToolbar)
        self.navigationController.toolbarHidden=YES;
    [self addToolbarToView:webView];
    [self addPullToRefreshToWebview:webView];
}

/**
 * Users can open the slide-out menu by swiping right. This adds a visual
 * button to the bottom-left part of the screen that the user can tap on.
 */
- (void)addSliderMenuButtonToView:(UIView *)view
{
    BOOL alreadyHasSliderBtn = NO;
    NSArray *subviews = [view subviews];
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            alreadyHasSliderBtn = YES;
            break;
        }
    }
    if (!alreadyHasSliderBtn) {
        UIButton *sliderMenuBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [sliderMenuBtn addTarget:self.revealViewController
                   action:@selector(revealToggle:)
         forControlEvents:UIControlEventTouchUpInside];
        
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        CGFloat imageYposition = screenSize.height - 108;
        sliderMenuBtn.frame = CGRectMake(0, imageYposition, 13, 40);
        
    //    [ImageUtils addRoundedCornersToView:sliderMenuBtn
    //                         topLeftRadius:0
    //                         topRightRadius:5
    //                         bottomLeftRadius:0
    //                         bottomRightRadius:5];
        
        UIImage *buttonImageNormal = [UIImage imageNamed:@"side-tab.png"];
        [sliderMenuBtn setBackgroundImage:buttonImageNormal forState:UIControlStateNormal];
        
        [view addSubview:sliderMenuBtn];
    }
}

- (void)enableNavigationButtonsIfNecessary {
    if (self.navigationController.toolbarHidden && (self.currentWebView.canGoBack || self.currentWebView.canGoForward)) {
        // Any view that is controlled by the UINavigationController automatically has a toolbar. We just need to unhide it.
        self.navigationController.toolbarHidden=NO;
    }
    self.backBtn.enabled = self.currentWebView.canGoBack;
    self.forwardBtn.enabled = self.currentWebView.canGoForward;
}

- (void)addToolbarToView:(UIView *)view
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    self.backBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-icon.png"] style:UIBarButtonItemStylePlain target:self.currentWebView action:@selector(goBack)];
    self.forwardBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward-icon.png"] style:UIBarButtonItemStylePlain target:self.currentWebView action:@selector(goForward)];
    UIBarButtonItem *refreshBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.currentWebView action:@selector(reload)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:self.backBtn];
    [items addObject:spacer];
    [items addObject:self.forwardBtn];
    [items addObject:spacer];
    [items addObject:spacer];
    [items addObject:spacer];
    [items addObject:spacer];
    [items addObject:spacer];
    [items addObject:refreshBtn];
    
    self.toolbarItems = items;
}

- (void)addPullToRefreshToWebview:(UIWebView *)webView
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    
    [refreshControl addTarget:self action:@selector(refreshPage)
      forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)refreshPage {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [self.currentWebView reload];
    [self startPageLoadTimer];
    
    if (locationManager != nil)
        [locationManager startUpdatingLocation];
}
- (void)stopRefresh {
    [self.refreshControl endRefreshing];
}

- (BOOL)isHomeView {
    return self.currentNavigationItem != nil && [self.currentNavigationItem isHome];
}

- (void)fireWebPageEvents:(NSNumber *)attemptCount
{
    // If the OS sends a low-memory warning, any invisible pages will be nuked to free up ram.
    // The nuked pages will take a bit to start back up when they are visited again, so they
    // may not be immediately ready to receive events, so this will try sending the event every
    // 250ms until the page is ready, or until it hits the max number of attempts.
    WebViewReadyForNavItemPredicate *predicate = [[WebViewReadyForNavItemPredicate alloc] initWithWebView:self.currentWebView];
    if ([predicate evaluateWithObject:self.currentNavigationItem]) {
        NSString *eventToFireOnLoad = [self.currentNavigationItem eventToFireOnLoad];
        if (eventToFireOnLoad != nil && eventToFireOnLoad.length > 0) {
            [Jockey send:eventToFireOnLoad withPayload:@[] toWebView:self.currentWebView];
        }
    }
    else {
        if ([attemptCount intValue] < 12) { // try to contanct the page for a max of 3 seconds
            // try again in 250ms
            [self performSelector:@selector(fireWebPageEvents:) withObject:[NSNumber numberWithInt:[attemptCount intValue] + 1] afterDelay:0.25];
        }
    }
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    if (self.currentNavigationItem == nil) {
        // Since the first load doesn't involve SidebarViewController:prepareForSague: (where
        // currentNavigationItem is set), self.currentNavigationItem will be null for the
        // first/home page.
        SidebarViewController *sidebarVC = [self getSidebarViewController];
        self.currentNavigationItem = [sidebarVC homeNavigationItem];
    }
    
    if ([self.currentNavigationItem needsUserLocation]) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        [locationManager startUpdatingLocation];
    }
    
	[self.navigationController setNavigationBarHidden:YES];
    
    // Make it so a swipe-right gesture will reveal the sidebar menu.
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
//	self.title = NSLocalizedString(@"WebTitle", @"");
    
    if (self.url == nil || [self.url isEqualToString:@"dynamic"]) {
        NavigationItem *firstNavItem = [[AppSettings navigationItems] objectAtIndex:0];
        SidebarViewController *sidebarViewController = [self getSidebarViewController];
        BOOL didRedirect = [sidebarViewController prepareWebView:self withNavigationItem:firstNavItem];
        if (didRedirect)
            return;
    }
    
    [self _createWebViewIfNecessaryForUrl:self.url];
    
    if ([self isHomeView]) {
        if (!self.currentWebView.canGoBack) {
            [Jockey send:@"loadHomePage" withPayload:@[] toWebView:self.currentWebView];
        }
        else {
            // If the Menu webview managed to navigate elsewhere, accidentally, we need to make it go back.
            // HOWEVER, it will fail to go back unless we wait for the sidebar to close, so we do this step
            // in the viewDidAppear method instead of here.
            //[self.currentWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60*60]];
        }
    }
    else {
        [self fireWebPageEvents:@0];
    }
    [JockeyjsAlerts listen];
    [JockeyjsSimpleStorage listen];
    
    // Moved to WebViewCache
//    if (self.currentWebView.request) {
//        // Turns out, calling reload is not necessary, and we can just display
//        // the webview as is.
//        // Calling reload typically won't reload the page if webivew.restorationIdentifier
//        // is set, but occasionally it does reload, which is frustrating.
//        //[self.currentWebView reload];
//    }
//    else
//        [self.currentWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60*60]]; // Caches the page for 1 hour
}

/*
 * Removes and re-creates the current web view.
 *
 * This is useful for when calling the reload: method isn't sufficient (such as when the original
 * page wasn't available and the app is now on the error page (don't want to reload that), or when
 * you want to nuke the page history).
 *
 * WARNING: Use deletePageHistory with care.
 * Since it deletes and re-creates the web view, it can cause problems if the
 * current web view is already showing.  Specifically, if self.refreshControl is
 * replaced WHILE the app is using the refresh control (i.e. if pull-to-refresh
 * is in progress), the app will crash.
 */
- (void)_forceReloadWebView:(BOOL)deletePageHistory
{
    if (deletePageHistory) {
        // Nuke the old webview so that it also nukes the history
        [WebViewCache removeCachedWebViewForUrl:self.url];
        
        // Create & load a new webview
        [self _createWebViewIfNecessaryForUrl:self.url];
    }
    else {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES]; // Hide any existing loading spinners, if any
        [MBProgressHUD showHUDAddedTo:self.view animated:NO]; // Show loading spinner
        [self.currentWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60*60]]; // Caches the page for 1 hour
    }
}

#pragma mark - UIViewController delegate methods

- (void)_reloadWebViewIfNavToolbarIsErroneouslyShowing
{
    // If the current webview is one that should be hiding the toolbar, but the webview managed to navigate
    // elsewhere, accidentally (and, therefore, the toolbar is now showing), we need to reload the page to
    // nuke the history, etc., so that the toolbar can be hidden again.
    if (self.hideWebviewToolbar && self.currentWebView.canGoBack) {
        
        [self _forceReloadWebView:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    self.currentWebView.delegate = self;	// setup the delegate as the web view is shown
    
    [self _reloadWebViewIfNavToolbarIsErroneouslyShowing];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopPageLoadTimer];
    [super viewWillDisappear:animated];
    
    [self.currentWebView stopLoading];	// in case the web view is still loading its content
	self.currentWebView.delegate = nil;	// disconnect the delegate as the webview is hidden
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

// this helps dismiss the keyboard when the "Done" button is clicked
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	[self.currentWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[textField text]]]];
	
	return YES;
}


#pragma mark - UIWebViewDelegate

/**
 * Jockey is used to send messages to/from the webview. This intercepts communication intended solely for Jockey.
 */
- (BOOL)_interceptJockeyCommunicationIfNecessary:(NSURLRequest *)request webView:(UIWebView *)webView
{
    // Get current URL of the webview through Javascript.
    NSString *urlString = [self.currentWebView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    if ([urlString isEqualToString:@"about:blank"]) {
        // This means nothing has loaded into the web view yet, which means self.url is ABOUT
        // to be loaded.
        urlString = self.url;
    }
    NSURL *currentURL = [NSURL URLWithString:urlString];
    
    NSString *host = [currentURL host];
    
    if (host == nil) {
        // This means window.location.href was other than "about:blank", but it still doesn't
        // have a host...
        // If that ever comes up, we'll assume whatever it is is not Jockey-safe and we'll
        // bypass sending the url to Jockey.
        NSLog(@"Unexpected URL \"%@\", bypassing JockeyJS...", urlString);
        return YES;
    }
    else {
        // If we DO know the host, we only want to have Jockey listen to the URLs if the site
        // is one we control.
        NSArray *domainsUsingJockeyJS = (NSArray *)[AppSettings getSetting:@"domainsUsingJockeyJS"];
        if (domainsUsingJockeyJS != nil && [domainsUsingJockeyJS count] > 0) {
            for (NSString *domainUsingJockeyJS in domainsUsingJockeyJS) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains %@", domainUsingJockeyJS];
                if ([predicate evaluateWithObject:host])
                    return [Jockey webView:webView withUrl:[request URL]];
            }
        }
        return YES;
    }
}

- (void)showLoadingSpinnerIfNecessary
{
    // We only want to show the loading spinner if/when the original URL is requested.
    // We don't want to show it for ajax requests and images, etc.
    NSString *pageUrl = [self.currentWebView.request.URL absoluteString];
    if (pageUrl == nil) {// If the page hasn't been loaded at all yet, this will be nil. It's non-nil by the time the first ajax request, etc. comes across.
        [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    }
}

/*
 * Opens the provided URL in the Google Maps app (if installed) or the Apple Maps
 * app IF it is a map-y url.
 */
- (BOOL)openUrlInNativeMapAppIfApplicable:(NSURL *)url
{
    BOOL openedInMapApp = NO;
    if ([@"maps.google.com" isEqualToString:[url host]] && [@"/maps" isEqualToString:[url path]]) {
        BOOL googleMapsIsAvailable = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps-x-callback://"]];
        if (googleMapsIsAvailable) {
            NSString *directionsRequest = [NSString stringWithFormat:@"%@%@", @"comgooglemaps-x-callback://?", [url query]];
            //                    @"&x-success=sourceapp://?resume=true&x-source=AirApp";
            NSURL *directionsURL = [NSURL URLWithString:directionsRequest];
            [[UIApplication sharedApplication] openURL:directionsURL];
            openedInMapApp = YES;
        }
        else {
            // Try to use the Apple Map app
                
            // For ios6+, we just need to replace the host with "maps.apple.com"
            NSString *newUrlStr = [[NSString alloc] initWithFormat:@"%@://maps.apple.com%@?%@", [url scheme], [url path], [url query]];
            NSURL *newURL = [NSURL URLWithString:newUrlStr];
            [[UIApplication sharedApplication] openURL:newURL];
            openedInMapApp = YES;
        }
    }
    return openedInMapApp;
}

/*
 * Opens the provided URL in this wrapper app if it matche any of the URLs of the 
 * configured navigationItems.
 */
- (BOOL)openUrlInThisAppIfApplicable:(NSURL *)url
{
    BOOL openedInThisApp = NO;
    NSString * urlStr = [url absoluteString];
    NavigationItem * navItem = [AppSettings getNavigationItemForUrl:urlStr];
    if (navItem != nil) {
        SidebarViewController *sidebarViewController = [self getSidebarViewController];
        if ([AppSettings getBooleanSetting:@"animateNavigationBetweenSidebarItems"])
            [sidebarViewController loadNavigationItemAnimated:navItem];
        else
            [sidebarViewController loadNavigationItem:navItem];
        openedInThisApp = YES;
    }
    return openedInThisApp;
}

- (BOOL)openInNativeAppIfApplicable:(NSURL *)url
{
    BOOL openedInNativeApp = [self openUrlInNativeMapAppIfApplicable:url];
    if (!openedInNativeApp)
        openedInNativeApp = [self openUrlInThisAppIfApplicable:url];
    return openedInNativeApp;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = request.URL;
    NSString *openInNewWindow = url[@"openInNewWindow"];
    if ([BooleanUtils booleanValue:openInNewWindow]) {
        NSURL *urlWithoutParam = [[url absoluteString] urlByRemovingQuerystringParam:@"openInNewWindow"];
        BOOL openedInNativeApp = [self openInNativeAppIfApplicable:urlWithoutParam];
        if (openedInNativeApp)
            return NO;
        else {
            [[UIApplication sharedApplication] openURL:urlWithoutParam];
            return NO;
        }
    }
    else {
        [self showLoadingSpinnerIfNecessary];
        return [self _interceptJockeyCommunicationIfNecessary:request webView:webView];
    }
}

NSTimer *_pageLoadTimer;
- (void)startPageLoadTimer
{
    if (_pageLoadTimer) {
        [self stopPageLoadTimer];
    }
    _pageLoadTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(displayPageLoadError) userInfo:nil repeats:NO];
}

- (void)stopPageLoadTimer
{
    if (_pageLoadTimer)
        [_pageLoadTimer invalidate];
    _pageLoadTimer = nil;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    self.backBtn.enabled = NO;
    self.forwardBtn.enabled = NO;
    
    [self startPageLoadTimer];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self stopPageLoadTimer];
    
	// finished loading, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES]; // Hide the loading spinner
    [self stopRefresh];
    [self enableNavigationButtonsIfNecessary];
    [self _performOnLoadSelectors];
}

- (void)displayPageLoadError {
    [self displayPageLoadError:YES];
}

- (void)displayPageLoadError:(BOOL)includeOptionToKeepWaiting
{
    [self stopPageLoadTimer]; // Since this can be triggered by an unavailable internet and/or server, we need to kill the timer that might still be running.
    
    NSString *serverUnreachableMsg = [self.currentNavigationItem serverUnreachableMsg];
    if (serverUnreachableMsg == nil) {
        SidebarViewController *sidebarViewController = [self getSidebarViewController];
        if ([sidebarViewController currentNavItemUrlMatchesHomeUrl])
            serverUnreachableMsg = [AppSettings getSetting:@"defaultHomeServerUnreachableMsg"];
        else {
            NSString *serverDescription = [NSString stringWithFormat:@"the %@ servers", [self.currentNavigationItem label]];
            NSString *supportContactAddr = [AppSettings getSetting:@"supportContactAddress"];
            serverUnreachableMsg = [NSString stringWithFormat:[AppSettings getSetting:@"defaultExternalServerUnreachableMsg"], serverDescription, supportContactAddr];
        }
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"We're having trouble getting some data."
                                                    message:serverUnreachableMsg
                                                   delegate:self
                                          cancelButtonTitle:@"Reload Page"
                                          otherButtonTitles:nil];
    if (includeOptionToKeepWaiting) {
        [alert addButtonWithTitle:@"Keep Waiting"];
    }
    else {
        // We need some sort of button other than "Reload Page", otherwise they can get stuck
        // in an infinite loop of that alert showing if one page is unavailable with no way
        // of abandoning that tab and going to another (potentially available) tab.
        [alert addButtonWithTitle:@"Cancel"];
    }
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonLbl = [alertView buttonTitleAtIndex:buttonIndex];
    switch (buttonIndex) {
        case TryAgain:
            NSLog(@"Attempting to load the page again...");
            [self stopRefresh];
            [self _forceReloadWebView:NO];
            break;
            
        case KeepWaitingOrCancel:
        default:
            if ([buttonLbl isEqualToString:@"Cancel"]) {
                // Close the alert and open the slider menu so they can select a different/available page.
                [self stopRefresh];
                [WebViewCache removeCachedWebViewForUrl:self.url];
                [self.revealViewController revealToggle:self];
            }
            else {
                // Just close the alert and let it spin.
                //
                // If it's just a slow server and/or slow internet, then the page may eventually load when the server
                // responds. But, if there's NO internet/server, then it shouldn't have got to this point because the
                // "Keep Waiting" option should have been excluded from the alert.  However, if that options WASN'T
                // hidden from the alert, then the page will NEVER load, even if the internet/server eventually
                // becomes available. In that scenario, they'll just have to pull to refresh.
            }
            break;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// load error, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (error.code == NSURLErrorCancelled) {
        // This "error" is thrown when trying to reload a url that was already loaded
        // previously (i.e. loaded by calling [self.myWebView reload]).  It is not a
        // real error.
        return;
    }
    else if (error.code == 101) {
        NSString *failingUrl = [error userInfo][NSURLErrorFailingURLStringErrorKey];
        if (failingUrl != nil && [failingUrl hasPrefix:@"jockey:"]) {
            // This means that a page that is not allowed to send jockey events is trying
            // to send jockey events.
            // The white list for domains that are allowed to send jockey events is in
            // settings.plist > domainsUsingJockeyJS.
            [NSException raise:@"IMPROPERLY CONFIGURED" format:@"The domain of the page \"%@\" is not allowed to send jockey events to the native app.", [self url]];
        }
    }
    
    [self displayPageLoadError:NO];

}

- (BOOL)isCurrentlyVisible
{
    // A view is currently visible if window is non-null
    return self.isViewLoaded && self.view.window;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isCurrentlyVisible]) {
        [WebViewCache removeAllCachedWebViewsNotUsingUrl:self.url];
    }
    else {
        self.currentWebView = nil;
    }
}

@end