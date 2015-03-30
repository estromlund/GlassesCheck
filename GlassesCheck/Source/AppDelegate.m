//
//  AppDelegate.m
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/27/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "GCHGlassesChecker.h"

#import "RACStream+GCHAdditions.h"

#import <ReactiveCocoa/ReactiveCocoa.h>


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong) NSStatusItem *statusBarItem;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self _addStatusBarItem];

    [[[[[GCHGlassesChecker sharedChecker] glassesPresenceSignal]
       filterUntilValueOccursNumTimesInARow:20]
      distinctUntilChanged]
     subscribeNext:^(NSNumber *boxedPresenceValue) {
        [self _setStatusBarImageForGlassesPresence:[boxedPresenceValue intValue]];
    } error:^(NSError *error) {
        NSLog(@"Error!: %@", error);
    }];
}

#pragma mark - Actions

- (void)quitApp:(id)sender
{
    [NSApp terminate:nil];
}

#pragma mark - Private

- (void)_addStatusBarItem
{
    NSStatusItem *statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    NSMenu *statusBarMenu = [NSMenu new];
    NSString *quitItemTitle = NSLocalizedString(@"Quit", nil);
    [statusBarMenu addItemWithTitle:quitItemTitle action:@selector(quitApp:) keyEquivalent:@""];

    statusBarItem.menu = statusBarMenu;

    self.statusBarItem = statusBarItem;

    [self _setStatusBarImageForGlassesPresence:GCHGlassesPresenceUnknown];
}

- (void)_setStatusBarImageForGlassesPresence:(GCHGlassesPresence)glassesPresenceValue
{
    switch (glassesPresenceValue) {
        case GCHGlassesPresenceUnknown: {
            self.statusBarItem.image = [self _glassesUnknownImage];
        }
        break;

        case GCHGlassesPresenceFalse: {
            self.statusBarItem.image = [self _glassesOffImage];
        }
        break;

        case GCHGlassesPresenceTrue: {
            self.statusBarItem.image = [self _glassesOnImage];
        }
        break;
    }
}

- (NSImage *)_glassesOnImage
{
    NSImage *image = [NSImage imageNamed:@"glasses_on"];
    image.template = YES;

    return image;
}

- (NSImage *)_glassesOffImage
{
    NSImage *image = [NSImage imageNamed:@"glasses_off"];
    image.template = YES;

    return image;
}

- (NSImage *)_glassesUnknownImage
{
    NSImage *image = [NSImage imageNamed:@"glasses_unknown"];
    image.template = YES;

    return image;
}

@end
