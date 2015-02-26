//
//  JockeyAlerts.m
//
//  Created by Troy Evans on 1/17/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import "JockeyjsAlerts.h"
#import "Jockey.h"
#import <objc/runtime.h>


@implementation JockeyjsAlerts
static JockeyjsAlerts *_instance;
static char CURRENT_ALERT_CALLBACK_KEY;
static char CURRENT_WEB_VIEW_KEY;
static char CURRENT_BUTTON_LIST_KEY;

+ (void)listen {
    if (_instance == nil) {
        _instance = [[JockeyjsAlerts alloc] init];
    }
}

- (id)init {
    if (self) {
        [self addAlertListener];
        [self addConfirmListener];
    }
    return self;
}

- (void)addAlertListener {
    [Jockey on:@"alert" performAsync:^(UIWebView *webView, NSDictionary *payload, void (^complete)()) {
        NSString *btnLabel = payload[@"buttonLabel"];
        if (btnLabel == nil)
            btnLabel = @"OK";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:payload[@"title"]
                                                        message:payload[@"msg"]
                                                       delegate:self
                                              cancelButtonTitle:btnLabel
                                              otherButtonTitles:nil];
        objc_setAssociatedObject(alert, &CURRENT_ALERT_CALLBACK_KEY, complete, OBJC_ASSOCIATION_RETAIN);
        [alert show];
    }];
}

- (NSArray *)_fixButtonListOrderingIfNecessary:(NSArray *)buttonList {
    // iPhone alerts are odd in that, if (and only if) there are more than 2 elements in the
    // button list, "cancelButtonTitle" ends up being the LAST button UI's list.
    // Any other buttons that are added via addButtonWithTitle: just go in order.
    //
    // This moves the last element to the beginning, if there are more than 2 elements,
    // so that the buttons appear in the same order as the orginal button list.
    NSMutableArray *fixedButtonList = [[NSMutableArray alloc] init];
    if ([buttonList count] > 2) {
        NSInteger lastIndex = [buttonList count]-1;
        NSString *lastButton = buttonList[lastIndex];
        [fixedButtonList addObject:lastButton];
        
        for (int i=0; i<[buttonList count]-1; i++) {
            NSString *nextButton = buttonList[i];
            [fixedButtonList addObject:nextButton];
        }
    }
    else
        fixedButtonList = [buttonList mutableCopy];
    return fixedButtonList;
}

- (NSInteger)_fixButtonIndex:(NSInteger)buttonIndex forAlertView:(UIAlertView *)alertView {
    NSInteger fixedButtonIndex;
    NSArray *buttonList = objc_getAssociatedObject(alertView, &CURRENT_BUTTON_LIST_KEY);
    if ([buttonList count] > 2) {
        // Compensate for the screwy ios button ordering
        if (buttonIndex == 0)
            fixedButtonIndex = [buttonList count]-1;
        else
            fixedButtonIndex = buttonIndex - 1;
    }
    else
        fixedButtonIndex = buttonIndex;
    return fixedButtonIndex;
}

- (void)addConfirmListener {
    [Jockey on:@"confirm" performAsync:^(UIWebView *webView, NSDictionary *payload, void (^complete)()) {
        NSArray *buttonList = payload[@"buttonLabels"];
        buttonList = [self _fixButtonListOrderingIfNecessary:buttonList];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:payload[@"title"]
                                                        message:payload[@"msg"]
                                                       delegate:self
                                              cancelButtonTitle:buttonList[0]
                                              otherButtonTitles:nil];
        for (int i=1; i<[buttonList count]; i++) {
            NSString *additionalBtnLbl = buttonList[i];
            [alert addButtonWithTitle:additionalBtnLbl];
        }
        objc_setAssociatedObject(alert, &CURRENT_WEB_VIEW_KEY, webView, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(alert, &CURRENT_BUTTON_LIST_KEY, buttonList, OBJC_ASSOCIATION_RETAIN);
        [alert show];
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSInvocation *currentAlertCallback = objc_getAssociatedObject(alertView, &CURRENT_ALERT_CALLBACK_KEY);
    UIWebView *currentWebView = objc_getAssociatedObject(alertView, &CURRENT_WEB_VIEW_KEY);
    if (currentAlertCallback != nil) { // it's the alert box
        [currentAlertCallback invoke];
    }
    else if (currentWebView != nil) { // it's the confirm box
        buttonIndex = [self _fixButtonIndex:buttonIndex forAlertView:alertView];
        [Jockey send:@"confirm-callback" withPayload:@{@"buttonIndex": [NSString stringWithFormat:@"%d", (int)buttonIndex]} toWebView:currentWebView];
    }
    else {
        NSLog(@"Unrecognized alert callback.  Button index: %d", (int)buttonIndex);
    }
}
@end
