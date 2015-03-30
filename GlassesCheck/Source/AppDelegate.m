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
	self.statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	self.statusBarItem.image = [NSImage imageNamed:@"glasses_on"];
	self.statusBarItem.image.template = YES;
}

@end
