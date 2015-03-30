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

- (void)detectGlasses {
	// Start Camera
	cv::VideoCapture capture(0); // open default camera

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

		cv::imshow("Original", videoFrame);

		[self preprocessFrame:videoFrame];

		cv::vector <cv::Rect> detectorResults = [self featuresInFrame:videoFrame usingClassifier:eyePairDetector];

		if (![self exactlyOneFeatureDetected:detectorResults]) {
			continue;
		}

		cv::Rect eyeRect = detectorResults[0];

		cv::Mat areaBetweenEyesFrame = [self betweenEyesROIFromEyePairRect:eyeRect inFrame:videoFrame];
		cv::Mat blurredFrame = [self blurredFrameFromFrame:areaBetweenEyesFrame];
		cv::Mat edgesFrame = [self edgesFrameFromFrame:blurredFrame];

		cv::imshow("Preprocessed", videoFrame);
		cv::imshow("Between Eyes", areaBetweenEyesFrame);
		cv::imshow("Blurred", blurredFrame);
		cv::imshow("Edges", edgesFrame);

		long numContours = [self numberOfContoursInFrame:edgesFrame];

		if (numContours == 0) {
			NSLog(@"No glasses! (contour count %lu)", numContours);
		}
		else if (numContours > 1) {
			NSLog(@"Glasses! (contour count %lu)", numContours);
		}

		// Cancel if ESC is pressed
		int key = cv::waitKey(1);
		if (key == 27) {
			break;
		}
	}
}

- (BOOL)exactlyOneFeatureDetected:(cv::vector <cv::Rect> )results {
	return (results.size() == 1);
}

- (void)preprocessFrame:(cv::Mat)originalFrame {
	cv::cvtColor(originalFrame, originalFrame, CV_BGR2GRAY);
	cv::equalizeHist(originalFrame, originalFrame);
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
	cv::Mat eyeBoxFrame = containingFrame(eyePairRect);

	// Crop to area between eyes
	int width = 20;
	int height = eyePairRect.height;

	int middleX = eyePairRect.width / 2;
	int x1 = middleX - width / 2;
	int y1 = 0;

	cv::Rect betweenEyesRect = cv::Rect(x1,
	                                    y1,
	                                    width,
	                                    height);

	return eyeBoxFrame(betweenEyesRect);
}

- (cv::Mat)blurredFrameFromFrame:(cv::Mat)frame {
	cv::Mat blurFrame;
	cv::blur(frame, blurFrame, cv::Size(6, 6));

	return blurFrame;
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
