//
//  GCHImageProcessor.m
//  GlassesCheck
//
//  Created by Erik Stromlund on 4/2/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import "GCHImageProcessor.h"


@implementation GCHImageProcessor

+ (cv::CascadeClassifier)eyePairDetector
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

+ (GCHCameraFrame)preprocessFrame:(GCHCameraFrame)originalFrame
{
    cv::cvtColor(originalFrame, originalFrame, CV_BGR2GRAY);
    
    //    cv::equalizeHist(originalFrame, originalFrame);
    return originalFrame;
}

+ (cv::vector<cv::Rect> )featuresInFrame:(GCHCameraFrame)frame usingClassifier:(cv::CascadeClassifier)classifier
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

+ (BOOL)exactlyOneFeatureDetectedInResults:(cv::vector<cv::Rect> )results
{
    return (results.size() == 1);
}

+ (GCHCameraFrame)betweenEyesROIFromEyePairRect:(cv::Rect)eyePairRect inFrame:(GCHCameraFrame)containingFrame
{
    // Crop to area between eyes, 20px wide, and shifted up 10px
    int width = 20;
    int additionalHeight = 10;
    int height = eyePairRect.height + additionalHeight;
    
    int middleX = eyePairRect.x + eyePairRect.width / 2;
    int x1 = std::max(0, middleX + width / 2);
    int y1 = std::max(0, eyePairRect.y + additionalHeight);
    
    cv::Rect betweenEyesRect = cv::Rect(x1,
                                        y1,
                                        width,
                                        height);
    
    return containingFrame(betweenEyesRect);
}

+ (GCHCameraFrame)edgesFrameFromFrame:(GCHCameraFrame)frame
{
    int lowThreshold = 50;
    int ratio = 3;
    int kernel_size = 3;
    
    GCHCameraFrame edgesFrame;
    cv::Canny(frame, edgesFrame, lowThreshold, lowThreshold * ratio, kernel_size);
    
    return edgesFrame;
}

+ (long)numberOfContoursInFrame:(GCHCameraFrame)frame
{
    cv::vector<cv::vector<cv::Point> > contours;
    cv::vector<cv::Vec4i> hierarchy;
    
    cv::findContours(frame, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    
    return contours.size();
}

@end
