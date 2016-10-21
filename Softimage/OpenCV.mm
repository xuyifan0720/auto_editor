//
//  OpenCV.m
//  OpenCVSample_OSX
//
//
//  
//

// Put OpenCV include files at the top. Otherwise an error happens.
#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>

#import <Foundation/Foundation.h>
#import "OpenCV.h"

/// Converts an NSImage to Mat.
static void NSImageToMat(NSImage *image, cv::Mat &mat) {
    
    // Create a pixel buffer.
    NSBitmapImageRep *bitmapImageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    NSInteger width = [bitmapImageRep pixelsWide];
    NSInteger height = [bitmapImageRep pixelsHigh];
    CGImageRef imageRef = [bitmapImageRep CGImage];
    cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Draw all pixels to the buffer.
    cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
    cv::cvtColor(mat8uc4, mat8uc3, CV_RGBA2BGR);
    
    mat = mat8uc3;
}

/// Converts a Mat to NSImage.
static NSImage *MatToNSImage(cv::Mat &mat) {
    
    // Create a pixel buffer.
    assert(mat.elemSize() == 1 || mat.elemSize() == 3);
    cv::Mat matrgb;
    if (mat.elemSize() == 1) {
        cv::cvtColor(mat, matrgb, CV_GRAY2RGB);
    } else if (mat.elemSize() == 3) {
        cv::cvtColor(mat, matrgb, CV_BGR2RGB);
    }
    
    // Change a image format.
    NSData *data = [NSData dataWithBytes:matrgb.data length:(matrgb.elemSize() * matrgb.total())];
    CGColorSpaceRef colorSpace;
    if (matrgb.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(matrgb.cols, matrgb.rows, 8, 8 * matrgb.elemSize(), matrgb.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    NSImage *image = [[NSImage alloc]init];
    [image addRepresentation:bitmapImageRep];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

static cv::Mat maskCreation(cv::Mat img)
{
    // cv::Mat img;
    cv::Mat gray, hsvimg, ycrcbimg, skinMask, skinMask1, skinMask2, canny;
    // NSImageToMat(image,img);
    cv::cvtColor(img, ycrcbimg, CV_BGR2YCrCb);
    cv::cvtColor(img, hsvimg, CV_BGR2HSV);
    cv::cvtColor(img, gray, CV_BGR2GRAY);
    cv::inRange(hsvimg, cv::Scalar(7,90,100), cv::Scalar(14,255,255), skinMask1);
    cv::inRange(ycrcbimg, cv::Scalar(130,130,70), cv::Scalar(255,175,135), skinMask2);
    cv::add(skinMask1, skinMask2, skinMask);
    cv::GaussianBlur(gray, gray, cv::Size(3,3), 0);
    cv::Canny(gray, canny, 15,16);
    cv::convertScaleAbs(canny,canny);
    //return canny;
    cv::bitwise_and(canny, skinMask, canny);
    
    cv::GaussianBlur(canny, canny, cv::Size(5,5), 0);
    for (int i = 0; i < canny.rows; i ++)
    {
        for (int j = 0; j < canny.cols; j ++)
        {
            cv::Scalar intensity = canny.at<uchar>(i, j);
            if (intensity.val[0] < 0.05)
            {
                canny.at<uchar>(i, j) = 0;
            }
            else
            {
                canny.at<uchar>(i, j) = 255;
            }
        }
    }
    return canny;
}

static float brightnessCalc (cv::Mat img)
{
    cv::Scalar avgPixelIntensity = cv::mean( img );
    float b = avgPixelIntensity[0];
    float g = avgPixelIntensity[1];
    float r = avgPixelIntensity[2];
    return sqrt(0.241 * (r * r) + 0.691 * (g * g) + 0.068 * (b * b));
}

static cv::Mat adjust_gamma (cv::Mat image, float constant)
{
    // adjusts brightness, yet to implement
    cv::Mat lookUpTable(1, 256, CV_8U);
    uchar* p = lookUpTable.data;
    for (int i = 0; i < 256; i ++)
    {
        float inverse = 1.0/constant;
        p[i] = pow(i/255.0,inverse) * 255;
    }
    cv::LUT(image, lookUpTable, image);
    return image;
}
static cv::Mat contrast_adjustment (cv::Mat image, float constant)
{
    // adjusts contrast, yet to implement
    cv::Mat lookUpTable(1, 256, CV_8U);
    uchar* p = lookUpTable.data;
    for (int i = 0; i < 128; i ++)
    {
        p[i] = pow(0.5,1 - constant) * pow(i/255.0, constant) * 255.0;
    }
    for (int i = 128; i < 256; i ++)
    {
        p[i] = -pow(0.5,1 - constant) * pow((1-i/255.0), constant) * 255 + 255;
    }
    cv::LUT(image, lookUpTable, image);
    return image;
}

@implementation OpenCV

+ (NSImage *)cvtColorBGR2GRAY:(NSImage *)image {
    cv::Mat bgrMat;
    NSImageToMat(image, bgrMat);
    cv::Mat grayMat;
    cv::cvtColor(bgrMat, grayMat, CV_BGR2GRAY);
    NSImage *grayImage = MatToNSImage(grayMat);
    return grayImage;
}

+ (NSImage *)cvtColorBGR2HSV:(NSImage *)image{
    cv::Mat bgrMat;
    NSImageToMat(image, bgrMat);
    cv::Mat hsvMat;
    cv::cvtColor(bgrMat, hsvMat, CV_BGR2HSV);
    NSImage *hsvImage = MatToNSImage(hsvMat);
    
    return hsvImage;
}

+ (NSImage *)cvtColorBGR2YCR_CB:(NSImage *)image{
    cv::Mat bgrMat;
    NSImageToMat(image, bgrMat);
    cv::Mat ycrcbMat;
    cv::cvtColor(bgrMat, ycrcbMat, CV_BGR2YCrCb);
    NSImage *ycrcbImage = MatToNSImage(ycrcbMat);
    
    return ycrcbImage;
}

+ (NSImage *)cvtMedianBlur:(NSImage *)image size:(int)size{
    cv::Mat bgrMat;
    NSImageToMat(image, bgrMat);
    cv::Mat dstMat;
    cv::medianBlur(bgrMat, dstMat, size);
    
    NSImage *blurImage = MatToNSImage(dstMat);
    return blurImage;
    
}

+ (NSImage *)cvtInRange:(NSImage *)image rl:(int)rl gl:(int)gl bl:(int)bl rh:(int)rh gh:(int)gh bh:(int)bh{
    cv::Mat bgrMat;
    NSImageToMat(image, bgrMat);
    cv::Mat dstMat;
    cv::inRange(bgrMat, cv::Scalar(rl,gl,bl), cv::Scalar(rh,gh,bh), dstMat);
    
    NSImage *inRangeImage = MatToNSImage(dstMat);
    return inRangeImage;
}

+ (NSImage *)cvtGaussianBlur:(NSImage *)image xRange:(int)xRange yRange:(int)yRange{
    cv::Mat bgrMat;
    NSImageToMat(image, bgrMat);
    cv::Mat dstMat;
    //cv::medianBlur(bgrMat, dstMat, size);
    //cv::inRange(bgrMat, cv::Scalar(rl,gl,bl), cv::Scalar(rh,gh,bh), dstMat);
    cv::GaussianBlur(bgrMat, dstMat, cv::Size(xRange,yRange), 0.0);
    
    NSImage *blurImage = MatToNSImage(dstMat);
    return blurImage;
}


+ (NSImage *)adjust: (NSImage *) image brightness: (int) brightness blemish: (bool) blemish
{
    cv::Mat cvimg;
    cv::Mat blurred;
    NSImage* result;
    NSImageToMat(image, cvimg);
    float originalBrightness = brightnessCalc(cvimg);

    for (int i = 0; i < 5; i ++)
    {
        float current = brightnessCalc(cvimg);
        float constant = (brightness - current) * 0.01 + 1;
        cvimg = adjust_gamma(cvimg, constant);
    }
    float newBrightness = brightnessCalc(cvimg);
    float contrastConst = newBrightness/originalBrightness;
    if (blemish)
    {
        cv::Mat clearRegion;
        cv::Mat blurRegion;
        cv::Mat reverseMask;
        cv::Mat mask = maskCreation(cvimg);
        cv::bitwise_not(mask,reverseMask);
        cv::medianBlur(cvimg, blurred, 17);
        blurred.copyTo(blurRegion,mask);
        cvimg.copyTo(clearRegion,reverseMask);
        cv::add(clearRegion,blurRegion,cvimg);
    }
    cvimg = contrast_adjustment(cvimg, pow(contrastConst,1.1));
    result = MatToNSImage(cvimg);
    return result;
}


@end
