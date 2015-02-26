//
//  NUTCachingURLProtocol.h
//  WebWrapper
//
//  Created by Troy Evans on 1/27/14.
//  Copyright (c) 2014 Nutrislice. All rights reserved.
//
//  Overrides RNCachingURLProtocol:canInitWithRequest to only watch URL resources
//  that are specified in the settings file.
//

#import "RNCachingURLProtocol.h"

@interface NUTRCachingURLProtocol : RNCachingURLProtocol

@end
