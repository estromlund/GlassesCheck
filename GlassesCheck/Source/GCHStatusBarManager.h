//
//  GCHStatusBarManager.h
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/30/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GCHGlassesPresence.h"

@interface GCHStatusBarManager : NSObject

- (void)installAppStatusItem;
- (void)updateForGlassesPresence:(GCHGlassesPresence)presence;

@end
