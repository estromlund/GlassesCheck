//
//  GCHCamera.m
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/30/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import "GCHCamera.h"

#import <opencv2/opencv.hpp>


@interface GCHCamera ()

@property (assign) BOOL processStream;
@property (strong) dispatch_queue_t cameraQueue;

@end


@implementation GCHCamera

- (void)startStream
{
    if (!self.output ||
        ![self.output respondsToSelector:@selector(fetchedFrameFromCamera:)]) {
        return;
    }

    self.processStream = YES;
    self.cameraQueue = dispatch_queue_create("com.fathomworks.GlassesCheck.camera-stream-queue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(self.cameraQueue, ^{
        cv::VideoCapture capture(0);
        cv::Mat videoFrame;

        while (self.processStream) {
            capture >> videoFrame;
            [self.output fetchedFrameFromCamera:videoFrame];
        }
    });
}

- (void)endStream
{
    self.processStream = NO;
    self.cameraQueue = nil;
}

@end
