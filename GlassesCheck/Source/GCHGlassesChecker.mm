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

+ (void)detectGlasses {
	// Start Camera
	cv::VideoCapture capture(0); // open default camera

	if (capture.isOpened() == false) {
		return;
	}


	// Setup Detector
	NSString *eyePairCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_mcs_eyepair_small"
	                                                               ofType:@"xml"];
	const CFIndex CASCADE_NAME_LEN = 2048;
	char *CASCADE_NAME = (char *)malloc(CASCADE_NAME_LEN);
	CFStringGetFileSystemRepresentation((CFStringRef)eyePairCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);

	cv::CascadeClassifier eyePairDetector;
	eyePairDetector.load(CASCADE_NAME);


	// General Frame Processing Setup
	cv::Mat videoFrame;
	cv::vector <cv::Rect> eyeBox;
	double scalingFactor = 1.1;
	int minNeighbors = 2;
	int flags = 0;

	// Process each frame
	while (true) {
		// Store off capture into frame
		capture >> videoFrame;

		// Convert to gray and normalize image
		cv::cvtColor(videoFrame, videoFrame, CV_BGR2GRAY);
		cv::equalizeHist(videoFrame, videoFrame);

		// Detect eye pair
		eyePairDetector.detectMultiScale(videoFrame, eyeBox,
		                                 scalingFactor, minNeighbors, flags,
		                                 cv::Size(30, 30));

		// Only continue iff there is an eye pair detected
		if (eyeBox.size() == 0 || eyeBox.size() > 1) {
			continue;
		}

		cv::Rect eyeRect = eyeBox[0];

		// Crop to eye region
		cv::Mat eyeBoxFrame = videoFrame(eyeRect);

		// Crop to area between eyes
		int width = 20;
		int height = eyeRect.height;

		int middleX = eyeRect.width / 2;
		int x1 = middleX - width / 2;
		int y1 = 0;

		cv::Rect betweenEyesRect = cv::Rect(x1,
		                                    y1,
		                                    width,
		                                    height);

		cv::Mat areaBetweenEyesFrame = eyeBoxFrame(betweenEyesRect);

		// Blur
		cv::Mat blurFrame;
		cv::blur(areaBetweenEyesFrame, blurFrame, cv::Size(6, 6));

		// Edge Detection
		int lowThreshold = 50;
		int ratio = 3;
		int kernel_size = 3;

		cv::Mat edgesFrame;
		cv::Canny(blurFrame, edgesFrame, lowThreshold, lowThreshold * ratio, kernel_size);

		// Find and draw contours
		cv::vector <cv::vector <cv::Point> > contours;
		cv::vector <cv::Vec4i> hierarchy;

		cv::findContours(edgesFrame, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

		// Draw contours
		long numContours = contours.size();

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

@end
