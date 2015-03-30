//
//  RACStream+GCHAdditions.m
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/30/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import "RACStream+GCHAdditions.h"


@implementation RACStream (GCHAdditions)

- (instancetype)filterUntilValueOccursNumTimesInARow:(NSInteger)numTimes
{
    Class class = self.class;

    return [[self bind:^{
        __block id representativeValue = nil;
        __block NSInteger sameValueCount = 0;

        return ^(id x, BOOL *stop) {
            if (x != representativeValue && ![x isEqual:representativeValue]) {
                representativeValue = x;
                sameValueCount = 0;
            }

            sameValueCount++;

            if (sameValueCount == numTimes) {
                return [class return :x];
            } else {
                return [class empty];
            }
        };
    }] setNameWithFormat:@"[%@] -filterUntilValueOccursNumTimesInARow:%ld", self.name, (long)numTimes];
}

@end
