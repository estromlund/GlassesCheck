//
//  GCHCamera.h
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/30/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GCHTypes.h"

#import <opencv2/opencv.hpp>


@protocol GCHCameraOutput<NSObject>

- (void)fetchedFrameFromCamera:(GCHCameraFrame)frame;

@end


@interface GCHCamera : NSObject

@property (assign) id<GCHCameraOutput> output;

- (void)startStream;
- (void)endStream;

@end
