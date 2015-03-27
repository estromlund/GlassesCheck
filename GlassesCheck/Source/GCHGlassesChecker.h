//
//  GCHGlassesChecker.h
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/27/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GCHGlassesChecker : NSObject

+ (instancetype)sharedChecker;

- (void)detectGlasses;

@end
