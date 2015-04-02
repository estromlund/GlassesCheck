//
//  GCHImageProcessor.h
//  GlassesCheck
//
//  Created by Erik Stromlund on 4/2/15.
//  Copyright (c) 2015 FathomWorks LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GCHTypes.h"

#import <opencv2/opencv.hpp>


@interface GCHImageProcessor : NSObject

+ (cv ::CascadeClassifier)eyePairDetector;

+ (GCHCameraFrame)preprocessFrame:(GCHCameraFrame)originalFrame;

+ (cv ::vector<cv ::Rect> )featuresInFrame:(GCHCameraFrame)frame usingClassifier:(cv ::CascadeClassifier)classifier;
+ (BOOL)exactlyOneFeatureDetectedInResults:(cv ::vector<cv ::Rect> )results;

+ (GCHCameraFrame)betweenEyesROIFromEyePairRect:(cv ::Rect)eyePairRect inFrame:(GCHCameraFrame)containingFrame;

+ (GCHCameraFrame)edgesFrameFromFrame:(GCHCameraFrame)frame;
+ (long)numberOfContoursInFrame:(GCHCameraFrame)frame;

@end
