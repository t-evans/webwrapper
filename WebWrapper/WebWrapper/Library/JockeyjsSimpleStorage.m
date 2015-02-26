//
//  JockeyjsSimpleStorage.m
//  WebWrapper
//
//  Created by Troy Evans on 4/22/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//

#import "JockeyjsSimpleStorage.h"
#import "Jockey.h"

@implementation JockeyjsSimpleStorage
static JockeyjsSimpleStorage *_instance;

+ (void)listen {
    if (_instance == nil) {
        _instance = [[JockeyjsSimpleStorage alloc] init];
    }
}

- (id)init {
    if (self) {
        [self addSaveListener];
//        [self addRetrieveListener];
    }
    return self;
}

- (void)addSaveListener {
    [Jockey on:@"save" performAsync:^(UIWebView *webView, NSDictionary *payload, void (^complete)()) {
        NSString *key = payload[@"key"];
        NSString *value = payload[@"value"];
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        if (value == [NSNull null])
            [userDefaults removeObjectForKey:key];
        else
            [userDefaults setObject:value forKey:key];
        [userDefaults synchronize];
        [complete invoke];
    }];
}

// Maybe one day. No need at present.
//- (void)addRetrieveListener {
//    [Jockey on:@"retrieve" performAsync:^(UIWebView *webView, NSDictionary *payload, void (^complete)()) {
//        NSString *key = payload[@"key"];
//        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
//        NSString *savedValue = [userDefaults stringForKey:key];
//        if (savedValue == nil)
//            savedValue = @"";
//        [complete invoke];
//        [Jockey send:@"retrieve-callback" withPayload:@{@"value": savedValue} toWebView:webView];
//    }];
//}
@end
