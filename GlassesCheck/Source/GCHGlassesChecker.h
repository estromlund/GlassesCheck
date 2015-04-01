//
//  GCHGlassesChecker.h
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/27/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSignal;


@interface GCHGlassesChecker : NSObject

// Turns on camera for first subscriber, and turns it off
// when no more subscribers are left
- (RACSignal *)glassesPresenceSignal;

@end
