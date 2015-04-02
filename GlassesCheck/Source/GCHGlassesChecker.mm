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


static const NSInteger kGCHThresholdForConfirmedPresenceChange = 15;


@implementation GCHGlassesChecker

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.presenceSubject = [RACReplaySubject replaySubjectWithCapacity:kGCHThresholdForConfirmedPresenceChange];
    }

    return self;
}

- (RACSignal *)glassesPresenceSignal
{
    return [[RACSignal createSignal:^RACDisposable *(id < RACSubscriber > subscriber) {
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
    }] filterUntilValueOccursNumTimesInARow:kGCHThresholdForConfirmedPresenceChange];
}

#pragma mark - <GCHCameraOutput>

- (void)fetchedFrameFromCamera:(GCHCameraFrame)videoFrame
{
    [self _detectGlassesInFrame:videoFrame];
}

#pragma mark - Private
#pragma mark Camera

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

#pragma mark Image Processing

- (void)_detectGlassesInFrame:(GCHCameraFrame)videoFrame
{
#if DEBUG_IMAGE_PROCESSING
    cv::flip(videoFrame, videoFrame, 1);
    cv::imshow("Original", videoFrame);
#endif

    // Preprocess the frame. At a minimum, new frame is converted
    // to gray. Could also equalize histogram, or blur as needed.
    videoFrame = [self preprocessFrame:videoFrame];

#if DEBUG_IMAGE_PROCESSING
    cv::imshow("Preprocessed", videoFrame);
#endif

    // Detect an eye pair using OpenCV's supplied detector.
    // We only want results where there is exactly one eye pair
    // No results: no person in frame, or bad detection
    // More than 1: bad detection, or > 1 person in frame, which is not supported
    static cv::CascadeClassifier eyePairDetector = [self eyePairDetector];
    cv::vector<cv::Rect> detectorResults = [self featuresInFrame:videoFrame usingClassifier:eyePairDetector];

    if (![self exactlyOneFeatureDetectedInResults:detectorResults]) {
#if DEBUG_IMAGE_PROCESSING
        NSLog(@"Skipping frame - <>1 eye pair detected.");
#endif
        [self.presenceSubject sendNext:@(GCHGlassesPresenceUnknown)];

        return;
    }

    // Crop the Eye Pair frame to focus on the upper nose area.
    // This is a "dumb" calculation which selects the middle
    // 20px of the Eye Pair frame.
    cv::Rect eyeRect = detectorResults[0];
    GCHCameraFrame areaBetweenEyesFrame = [self betweenEyesROIFromEyePairRect:eyeRect inFrame:videoFrame];

    // Find all the edges. In a match, this should sketch the
    // nose bridge portion of the glasses and nothing else.
    GCHCameraFrame edgesFrame = [self edgesFrameFromFrame:areaBetweenEyesFrame];

#if DEBUG_IMAGE_PROCESSING
    cv::imshow("Preprocessed", videoFrame);
    cv::imshow("Between Eyes", areaBetweenEyesFrame);
    cv::imshow("Edges", edgesFrame);
#endif

    // Using the edges we found earlier, count the number of
    // contours. In the no-detection case, there shouldn't be
    // any edges since it would just be the flat nose surface.
    //
    // For a detection, though, we expect there to be at least one
    // contour. There is perhaps room for improvement here, because
    // there should really only be exactly one contour if the proper
    // edges are detected in the earlier steps. Testing shows that
    // the results are good enough when just selecting numContours > 0
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

- (BOOL)exactlyOneFeatureDetectedInResults:(cv::vector<cv::Rect> )results
{
    return (results.size() == 1);
}

- (GCHCameraFrame)betweenEyesROIFromEyePairRect:(cv::Rect)eyePairRect inFrame:(GCHCameraFrame)containingFrame
{
    // Crop to area between eyes, 20px wide, and shifted up 10px
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
