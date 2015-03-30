//
//  GCHGlassesChecker.m
//  GlassesCheck
//
//  Created by Erik Stromlund on 3/27/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import "GCHGlassesChecker.h"

#import <opencv2/opencv.hpp>


@implementation GCHGlassesChecker

+ (instancetype)sharedChecker {
	static GCHGlassesChecker *_sharedChecker;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedChecker = [[self alloc] init];
	});

	return _sharedChecker;
}

- (void)detectGlasses {
    if ([NSThread isMainThread]) {
        [self performSelectorInBackground:@selector(detectGlasses) withObject:nil];
        return;
    }
    
	// Start Camera
	cv::VideoCapture capture(0);     // open default camera

	if (capture.isOpened() == false) {
		return;
	}

	// Setup Detector
	cv::CascadeClassifier eyePairDetector = [self eyePairDetector];

	// General Frame Processing Setup
	cv::Mat videoFrame;
	cv::vector <cv::Rect> detectorResults;

	// Process each frame
	while (true) {
		// Store off capture into frame
		capture >> videoFrame;

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
			continue;
		}

		cv::Rect eyeRect = detectorResults[0];

		cv::Mat areaBetweenEyesFrame = [self betweenEyesROIFromEyePairRect:eyeRect inFrame:videoFrame];
		cv::Mat edgesFrame = [self edgesFrameFromFrame:areaBetweenEyesFrame];

#if DEBUG_IMAGE_PROCESSING
		cv::imshow("Preprocessed", videoFrame);
		cv::imshow("Between Eyes", areaBetweenEyesFrame);
		cv::imshow("Edges", edgesFrame);
#endif

		long numContours = [self numberOfContoursInFrame:edgesFrame];

		if (numContours == 0) {
//			NSLog(@"No glasses! (contour count %lu)", numContours);
		}
		else {
//			NSLog(@"Glasses! (contour count %lu)", numContours);
		}
	}
}

- (cv::CascadeClassifier)eyePairDetector {
	NSString *eyePairCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_mcs_eyepair_small"
	                                                               ofType:@"xml"];
	const CFIndex CASCADE_NAME_LEN = 2048;
	char *CASCADE_NAME = (char *)malloc(CASCADE_NAME_LEN);
	CFStringGetFileSystemRepresentation((CFStringRef)eyePairCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);

	cv::CascadeClassifier eyePairDetector;
	eyePairDetector.load(CASCADE_NAME);

	return eyePairDetector;
}

- (BOOL)exactlyOneFeatureDetected:(cv::vector <cv::Rect> )results {
	return (results.size() == 1);
}

- (cv::Mat)preprocessFrame:(cv::Mat)originalFrame {
	cv::cvtColor(originalFrame, originalFrame, CV_BGR2GRAY);
//    cv::equalizeHist(originalFrame, originalFrame);
	return originalFrame;
}

- (cv::vector <cv::Rect> )featuresInFrame:(cv::Mat)frame usingClassifier:(cv::CascadeClassifier)classifier {
	double scalingFactor = 1.1;
	int minNeighbors = 2;
	int flags = 0;

	cv::vector <cv::Rect> detectorResults;

	classifier.detectMultiScale(frame, detectorResults,
	                            scalingFactor, minNeighbors, flags,
	                            cv::Size(30, 30));

	return detectorResults;
}

- (cv::Mat)betweenEyesROIFromEyePairRect:(cv::Rect)eyePairRect inFrame:(cv::Mat)containingFrame {
	// Crop to area between eyes
	int width = 20;
	int additionalHeight = 10;
	int height = eyePairRect.height + additionalHeight;

	int middleX = eyePairRect.x + eyePairRect.width / 2;
	int x1 = middleX - width / 2;
	int y1 = eyePairRect.y - additionalHeight;

	cv::Rect betweenEyesRect = cv::Rect(x1,
	                                    y1,
	                                    width,
	                                    height);

	return containingFrame(betweenEyesRect);
}

- (cv::Mat)edgesFrameFromFrame:(cv::Mat)frame {
	int lowThreshold = 50;
	int ratio = 3;
	int kernel_size = 3;

	cv::Mat edgesFrame;
	cv::Canny(frame, edgesFrame, lowThreshold, lowThreshold * ratio, kernel_size);

	return edgesFrame;
}

- (long)numberOfContoursInFrame:(cv::Mat)frame {
	cv::vector <cv::vector <cv::Point> > contours;
	cv::vector <cv::Vec4i> hierarchy;

	cv::findContours(frame, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

	return contours.size();
}

@end
