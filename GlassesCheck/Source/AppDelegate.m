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

#import <GBHUD/GBHUD.h>
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

    [self lookForGlasses];
}

- (void)lookForGlasses
{
    [self _showStatusAsSearching];

    [[[[self.glassesPresenceChecker glassesPresenceSignal] distinctUntilChanged]
      takeUntilBlock:^BOOL (NSNumber *presenceValue) {
        return [presenceValue isEqual:@(GCHGlassesPresenceTrue)];
    }] subscribeCompleted:^{
        [self performSelectorOnMainThread:@selector(_showStatusAsDetected) withObject:nil waitUntilDone:NO];
    }];
}

#pragma mark - Status

- (void)_showStatusAsSearching
{
    [[GBHUD sharedHUD] showHUDWithType:GBHUDTypeLoading text:@"Glasses On?"];
}

- (void)_showStatusAsDetected
{
    [[GBHUD sharedHUD] dismissHUD];

    [self.statusBarManager updateForGlassesPresence:GCHGlassesPresenceTrue];
    [[GBHUD sharedHUD] showHUDWithType:GBHUDTypeSuccess text:@"Glasses Detected!"];
    [[GBHUD sharedHUD] autoDismissAfterDelay:2.0];
}

@end
