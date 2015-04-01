//
//  GCHStatusItemController.h
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/30/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GCHGlassesPresence.h"

#import <ReactiveCocoa/ReactiveCocoa.h>


@interface GCHStatusItemController : NSObject

@property (nonatomic, strong, readonly) RACCommand *detectNowCommand;

- (void)installAppStatusItem;
- (void)updateForGlassesPresence:(GCHGlassesPresence)presence;

@end
