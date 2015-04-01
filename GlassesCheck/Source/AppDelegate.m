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
#import "GCHStatusItemController.h"

#import <GBHUD/GBHUD.h>
#import <ReactiveCocoa/ReactiveCocoa.h>


@interface AppDelegate ()

@property (strong) GCHStatusItemController *statusItemController;
@property (strong) GCHGlassesChecker *glassesPresenceChecker;

@property (strong) RACSignal *becameActiveSignal;
@property (strong) RACSignal *resignActiveSignal;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.glassesPresenceChecker = [[GCHGlassesChecker alloc] init];

    self.statusItemController = [[GCHStatusItemController alloc] init];
    [self.statusItemController installAppStatusItem];
    
    [self.statusItemController.detectNowCommand.executionSignals subscribeNext:^(id x) {
        [self detectGlassesNow];
    }];

    [self startSessionLifecycleSignals];

    [self detectGlassesOnTimedInterval];
    [self detectGlassesWhenSessionBecomesActive];

    [self detectGlassesNow];
}

- (void)startSessionLifecycleSignals
{
    NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];

    RACSignal *willSleepSignal = [notificationCenter rac_addObserverForName:NSWorkspaceWillSleepNotification object:nil];
    RACSignal *logOutSignal = [notificationCenter rac_addObserverForName:NSWorkspaceSessionDidResignActiveNotification object:nil];
    self.resignActiveSignal = [RACSignal merge:@[willSleepSignal, logOutSignal]];

    RACSignal *didWakeSignal = [notificationCenter rac_addObserverForName:NSWorkspaceDidWakeNotification object:nil];
    RACSignal *logInSignal = [notificationCenter rac_addObserverForName:NSWorkspaceSessionDidBecomeActiveNotification object:nil];
    self.becameActiveSignal = [RACSignal merge:@[didWakeSignal, logInSignal]];
}

- (void)detectGlassesOnTimedInterval
{
    [self setupTimerToStartOnActiveSession];
    [self turnOnTimerWhichCancelsWhenSessionResigns];
}

- (void)setupTimerToStartOnActiveSession
{
    [self.becameActiveSignal subscribeNext:^(__unused id x) {
        [self turnOnTimerWhichCancelsWhenSessionResigns];
    }];
}

- (void)turnOnTimerWhichCancelsWhenSessionResigns
{
    NSTimeInterval thirtyMinutes = 30 * 60;
    RACSignal *timerSignal = [RACSignal interval:thirtyMinutes onScheduler:[RACScheduler currentScheduler] withLeeway:0];

    [[timerSignal takeUntil:self.resignActiveSignal] subscribeNext:^(__unused id x) {
        [self detectGlassesNow];
    }];
}

- (void)detectGlassesWhenSessionBecomesActive
{
    [self.becameActiveSignal subscribeNext:^(__unused id x) {
        [self detectGlassesNow];
    }];
}

- (void)detectGlassesNow
{
    [self performSelectorOnMainThread:@selector(_showStatusAsSearching) withObject:nil waitUntilDone:NO];

    RACSignal *presenceSignal = self.glassesPresenceChecker.glassesPresenceSignal;

    [[[[[presenceSignal distinctUntilChanged]
        takeUntil:self.resignActiveSignal]
       takeUntilBlock:^BOOL (NSNumber *presenceValue) {
        return [presenceValue isEqual:@(GCHGlassesPresenceTrue)];
    }]
      deliverOnMainThread]
     subscribeCompleted:^{
        [self _showStatusAsDetected];
    }];
}

#pragma mark - Status

- (void)_showStatusAsSearching
{
    GBHUD *hud = [GBHUD sharedHUD];
    [hud showHUDWithType:GBHUDTypeLoading text:@"Glasses On?"];
}

- (void)_showStatusAsDetected
{
    [[GBHUD sharedHUD] dismissHUD];

    [self.statusItemController updateForGlassesPresence:GCHGlassesPresenceTrue];
    [[GBHUD sharedHUD] showHUDWithType:GBHUDTypeSuccess text:@"Glasses Detected!"];
    [[GBHUD sharedHUD] autoDismissAfterDelay:2.0];
}

@end
