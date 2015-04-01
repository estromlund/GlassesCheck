//
//  GCHStatusBarManager.m
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/30/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import "GCHStatusBarManager.h"

#import <AppKit/AppKit.h>


@interface GCHStatusBarManager ()

@property (strong) NSStatusItem *statusBarItem;

@end


@implementation GCHStatusBarManager

- (void)installAppStatusItem
{
    NSStatusItem *statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    NSMenu *statusBarMenu = [NSMenu new];

    NSString *quitItemTitle = NSLocalizedString(@"Quit", nil);
    NSMenuItem *quitItem = [statusBarMenu addItemWithTitle:quitItemTitle action:@selector(quitApp:) keyEquivalent:@""];
    quitItem.enabled = YES;

    statusBarItem.menu = statusBarMenu;

    self.statusBarItem = statusBarItem;

    [self updateForGlassesPresence:GCHGlassesPresenceUnknown];
}

- (void)updateForGlassesPresence:(GCHGlassesPresence)glassesPresenceValue
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

#pragma mark - Private

#pragma mark Actions

- (void)quitApp:(id)sender
{
    [NSApp terminate:nil];
}

#pragma mark Images

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
