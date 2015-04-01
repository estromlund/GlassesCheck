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

#pragma mark - Detection Methods

- (void)detectGlassesOnTimedInterval
{
    [self setupTimerToStartOnActiveSession];
    [self turnOnTimerWhichCancelsWhenSessionResigns];
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

    // Give up if session ends (i.e. logout or sleep), or if X seconds pass
    RACSignal *timeoutSignal = [RACSignal interval:30 onScheduler:[RACScheduler currentScheduler]];
    RACSignal *cancelSignal = [RACSignal merge:@[self.resignActiveSignal, timeoutSignal]];
    [[cancelSignal deliverOnMainThread]
     subscribeNext:^(id x) {
        [self _showStatusAsCanceledAndUndetermined];
    }];


    [[[[[self.glassesPresenceChecker.glassesPresenceSignal
         distinctUntilChanged]
        takeUntil:cancelSignal]
       takeUntilBlock:^BOOL (NSNumber *presenceValue) {
        return [presenceValue isEqual:@(GCHGlassesPresenceTrue)];
    }]
      deliverOnMainThread]
     subscribeCompleted:^{
        [self _showStatusAsDetected];
    }];
}

#pragma mark - Signal Setup

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

#pragma mark - Timer

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

#pragma mark - Status Updates

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

- (void)_showStatusAsCanceledAndUndetermined
{
    [self.statusItemController updateForGlassesPresence:GCHGlassesPresenceUnknown];
}

@end
