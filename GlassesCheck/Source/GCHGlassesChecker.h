//
//  GCHGlassesChecker.h
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/27/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSignal;


typedef NS_ENUM (NSInteger, GCHGlassesPresence) {
    GCHGlassesPresenceUnknown,
    GCHGlassesPresenceFalse,
    GCHGlassesPresenceTrue,
};


@interface GCHGlassesChecker : NSObject

+ (instancetype)sharedChecker;

- (RACSignal *)glassesPresenceSignal;

@end
