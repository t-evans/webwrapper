//
//  JockeyAlerts.h
//
//  Created by Troy Evans on 1/16/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//
// This class adds listeners for the jockeyjs.alerts.js javascript library
// to display native alerts.
//
// Activate with [JockeyAlerts listen];
//

#import <Foundation/Foundation.h>

@interface JockeyjsAlerts : NSObject
+ (void)listen;
@end
