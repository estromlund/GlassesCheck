//
//  GCHStatusItemController.m
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/30/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import "GCHStatusItemController.h"

#import <AppKit/AppKit.h>


@interface GCHStatusItemController ()

@property (strong) RACCommand *detectNowCommand;

@property (strong) NSStatusItem *statusBarItem;

@end


@implementation GCHStatusItemController

- (void)installAppStatusItem
{
    NSStatusItem *statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    NSMenu *statusBarMenu = [NSMenu new];

    NSString *detectNowTitle = NSLocalizedString(@"Detect Now", nil);
    NSMenuItem *detectNowItem = [statusBarMenu addItemWithTitle:detectNowTitle action:@selector(detectNow:) keyEquivalent:@""];
    detectNowItem.target = self;

    [statusBarMenu addItem:[NSMenuItem separatorItem]];

    NSString *quitItemTitle = NSLocalizedString(@"Quit", nil);
    NSMenuItem *quitItem = [statusBarMenu addItemWithTitle:quitItemTitle action:@selector(quitApp:) keyEquivalent:@""];
    quitItem.target = self;

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

#pragma mark - Accessors

- (RACCommand *)detectNowCommand
{
    if (!_detectNowCommand) {
        _detectNowCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(__unused id input) {
            return [RACSignal empty];
        }];
    }

    return _detectNowCommand;
}

#pragma mark - Private

#pragma mark Actions

- (void)detectNow:(id)sender
{
    [self.detectNowCommand execute:nil];
}

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
