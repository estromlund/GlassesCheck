//
//  GCHGlassesChecker.m
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/27/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import "GCHGlassesChecker.h"

#import "GCHCamera.h"
#import "GCHGlassesPresence.h"
#import "GCHTypes.h"

#import "RACStream+GCHAdditions.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <opencv2/opencv.hpp>


@interface GCHGlassesChecker ()<GCHCameraOutput>

@property (strong) RACReplaySubject *presenceSubject;
@property (assign) NSInteger numberOfSubscribers;

@property (strong) GCHCamera *camera;

@end


@implementation GCHGlassesChecker

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.presenceSubject = [RACReplaySubject replaySubjectWithCapacity:10];
    }

    return self;
}

- (RACSignal *)glassesPresenceSignal
{
    return [[[RACSignal createSignal:^RACDisposable *(id < RACSubscriber > subscriber) {
        @synchronized(self)
        {
            if (self.numberOfSubscribers == 0) {
                [self _startCapturingVideo];
            }

            ++self.numberOfSubscribers;
        }

        [self.presenceSubject subscribe:subscriber];

        return [RACDisposable disposableWithBlock:^{
            @synchronized(self)
            {
                --self.numberOfSubscribers;

                if (self.numberOfSubscribers == 0) {
                    [self _stopCapturingVideo];
                }
            }
        }];
    }] logAll] filterUntilValueOccursNumTimesInARow:15];
}

- (void)_startCapturingVideo
{
    self.camera = [GCHCamera new];
    self.camera.output = self;
    [self.camera startStream];
}

- (void)_stopCapturingVideo
{
    [self.camera endStream];
}

- (void)fetchedFrameFromCamera:(GCHCameraFrame)videoFrame
{
    static cv::CascadeClassifier eyePairDetector = [self eyePairDetector];

    cv::vector<cv::Rect> detectorResults;

#if DEBUG_IMAGE_PROCESSING
    cv::flip(videoFrame, videoFrame, 1);
    cv::imshow("Original", videoFrame);
#endif

    videoFrame = [self preprocessFrame:videoFrame];

#if DEBUG_IMAGE_PROCESSING
    cv::imshow("Preprocessed", videoFrame);
#endif

    detectorResults = [self featuresInFrame:videoFrame usingClassifier:eyePairDetector];

    if (![self exactlyOneFeatureDetected:detectorResults]) {
#if DEBUG_IMAGE_PROCESSING
        NSLog(@"Skipping frame - <>1 eye pair detected.");
#endif
        [self.presenceSubject sendNext:@(GCHGlassesPresenceUnknown)];

        return;
    }

    cv::Rect eyeRect = detectorResults[0];

    GCHCameraFrame areaBetweenEyesFrame = [self betweenEyesROIFromEyePairRect:eyeRect inFrame:videoFrame];
    GCHCameraFrame edgesFrame = [self edgesFrameFromFrame:areaBetweenEyesFrame];

#if DEBUG_IMAGE_PROCESSING
    cv::imshow("Preprocessed", videoFrame);
    cv::imshow("Between Eyes", areaBetweenEyesFrame);
    cv::imshow("Edges", edgesFrame);
#endif

    long numContours = [self numberOfContoursInFrame:edgesFrame];

    if (numContours == 0) {
        [self.presenceSubject sendNext:@(GCHGlassesPresenceFalse)];
    } else {
        [self.presenceSubject sendNext:@(GCHGlassesPresenceTrue)];
    }
}

- (cv::CascadeClassifier)eyePairDetector
{
    NSString *eyePairCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_mcs_eyepair_small"
                                                                   ofType:@"xml"];
    const CFIndex CASCADE_NAME_LEN = 2048;
    char *CASCADE_NAME = (char *)malloc(CASCADE_NAME_LEN);
    CFStringGetFileSystemRepresentation((CFStringRef)eyePairCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);

    cv::CascadeClassifier eyePairDetector;
    eyePairDetector.load(CASCADE_NAME);

    return eyePairDetector;
}

- (BOOL)exactlyOneFeatureDetected:(cv::vector<cv::Rect> )results
{
    return (results.size() == 1);
}

- (GCHCameraFrame)preprocessFrame:(GCHCameraFrame)originalFrame
{
    cv::cvtColor(originalFrame, originalFrame, CV_BGR2GRAY);

//    cv::equalizeHist(originalFrame, originalFrame);
    return originalFrame;
}

- (cv::vector<cv::Rect> )featuresInFrame:(GCHCameraFrame)frame usingClassifier:(cv::CascadeClassifier)classifier
{
    double scalingFactor = 1.1;
    int minNeighbors = 2;
    int flags = 0;

    cv::vector<cv::Rect> detectorResults;

    classifier.detectMultiScale(frame, detectorResults,
                                scalingFactor, minNeighbors, flags,
                                cv::Size(30, 30));

    return detectorResults;
}

- (GCHCameraFrame)betweenEyesROIFromEyePairRect:(cv::Rect)eyePairRect inFrame:(GCHCameraFrame)containingFrame
{
    // Crop to area between eyes
    int width = 20;
    int additionalHeight = 10;
    int height = eyePairRect.height + additionalHeight;

    int middleX = eyePairRect.x + eyePairRect.width / 2;
    int x1 = std::max(0, middleX - width / 2);
    int y1 = std::max(0, eyePairRect.y - additionalHeight);

    cv::Rect betweenEyesRect = cv::Rect(x1,
                                        y1,
                                        width,
                                        height);

    return containingFrame(betweenEyesRect);
}

- (GCHCameraFrame)edgesFrameFromFrame:(GCHCameraFrame)frame
{
    int lowThreshold = 50;
    int ratio = 3;
    int kernel_size = 3;

    GCHCameraFrame edgesFrame;
    cv::Canny(frame, edgesFrame, lowThreshold, lowThreshold * ratio, kernel_size);

    return edgesFrame;
}

- (long)numberOfContoursInFrame:(GCHCameraFrame)frame
{
    cv::vector<cv::vector<cv::Point> > contours;
    cv::vector<cv::Vec4i> hierarchy;

    cv::findContours(frame, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

    return contours.size();
}

@end
