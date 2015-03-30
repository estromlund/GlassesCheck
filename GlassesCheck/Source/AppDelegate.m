//
//  AppDelegate.m
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/27/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "GCHGlassesChecker.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong) NSStatusItem *statusBarItem;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self _addStatusBarItem];

	[[GCHGlassesChecker sharedChecker] detectGlasses];
}

- (void)_addStatusBarItem {
	NSStatusItem *statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	statusBarItem.image = [NSImage imageNamed:@"glasses_on"];
	statusBarItem.image.template = YES;

	NSMenu *statusBarMenu = [NSMenu new];
	NSString *quitItemTitle = NSLocalizedString(@"Quit", nil);
	[statusBarMenu addItemWithTitle:quitItemTitle action:@selector(quitApp:) keyEquivalent:@""];

	statusBarItem.menu = statusBarMenu;

	self.statusBarItem = statusBarItem;
}

#pragma mark - Actions

- (void)quitApp:(id)sender {
	[NSApp terminate:nil];
}

@end
