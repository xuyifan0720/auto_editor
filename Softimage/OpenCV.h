//
//  OpenCV.h
//  Credit of original sample belongs to OpenCVSample_OSX
//  Add more function based on my project needs.
//
//  
//

#import <Cocoa/Cocoa.h>

@interface OpenCV : NSObject

/// Converts a full color image to grayscale image with using OpenCV.
+ (NSImage *)cvtColorBGR2GRAY:(NSImage *)image;
+ (NSImage *)cvtColorBGR2HSV:(NSImage *)image;
+ (NSImage *)cvtColorBGR2YCR_CB:(NSImage *)image;
+ (NSImage *)cvtMedianBlur:(NSImage *)image size:(int)size;
+ (NSImage *)cvtInRange:(NSImage *)image rl:(int)rl gl:(int)gl bl:(int)bl rh:(int)rh gh:(int)gh bh:(int)bh;
+ (NSImage *)cvtGaussianBlur:(NSImage *)image xRange:(int)xRange yRange:(int)yRange;
+ (NSImage *)adjust: (NSImage *) image brightness:(int)brightness blemish:(bool)blemish;
@end
