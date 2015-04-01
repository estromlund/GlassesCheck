//
//  AppDelegate.m
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/27/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "GCHGlassesChecker.h"
#import "GCHGlassesPresence.h"
#import "GCHStatusBarManager.h"

#import <ReactiveCocoa/ReactiveCocoa.h>


@interface AppDelegate ()

@property (strong) GCHStatusBarManager *statusBarManager;
@property (strong) GCHGlassesChecker *glassesPresenceChecker;

@property (weak) IBOutlet NSWindow *window;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.statusBarManager = [[GCHStatusBarManager alloc] init];
    [self.statusBarManager installAppStatusItem];

    self.glassesPresenceChecker = [[GCHGlassesChecker alloc] init];

    [[[[self.glassesPresenceChecker glassesPresenceSignal] distinctUntilChanged]
      takeUntilBlock:^BOOL (NSNumber *presenceValue) {
        return [presenceValue isEqual:@(GCHGlassesPresenceFalse)];
    }] subscribeCompleted:^{
        [self.statusBarManager updateForGlassesPresence:GCHGlassesPresenceTrue];
    }];
}

@end
