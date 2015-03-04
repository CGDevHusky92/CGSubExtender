//
//  OpenCVMatrixTranslator.m
//  CGSubExtender
//
//  Created by Charles Gorectke on 11/18/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "CGOpenCVMatrixTranslator.h"
#import <CGSubExtender/CGSubExtender-Swift.h>

@implementation CGOpenCVMatrixTranslator

+ (UIImage *)cropImageView:(CGCropImageView *)imageView
{
    // Get the original matrix
    cv::Mat original = [self cvMatrixFromUIImage:imageView.image];
    CGCropView * cropView = imageView.cropView;
    NSArray * handles = cropView.cropHandles;
    
    CGFloat handleSize = 35.0;
    
    // Determine the X/Y scale factors
    CGFloat scaleX = cropView.frame.size.width / imageView.image.size.width;
    CGFloat scaleY = cropView.frame.size.height / imageView.image.size.height;
    
    
    // Determine the corner points, after scale/adjustment
    CGPoint topLeftPoint       = CGPointMake(((UIView*)[handles objectAtIndex:0]).frame.origin.x / scaleX + handleSize,
                                             ((UIView*)[handles objectAtIndex:0]).frame.origin.y / scaleY + handleSize);
    CGPoint topRightPoint      = CGPointMake(((UIView*)[handles objectAtIndex:2]).frame.origin.x / scaleX + handleSize,
                                             ((UIView*)[handles objectAtIndex:2]).frame.origin.y / scaleY + handleSize);
    CGPoint bottomRightPoint   = CGPointMake(((UIView*)[handles objectAtIndex:4]).frame.origin.x / scaleX + handleSize,
                                             ((UIView*)[handles objectAtIndex:4]).frame.origin.y / scaleY + handleSize);
    CGPoint bottomLeftPoint    = CGPointMake(((UIView*)[handles objectAtIndex:6]).frame.origin.x / scaleX + handleSize,
                                             ((UIView*)[handles objectAtIndex:6]).frame.origin.y / scaleY + handleSize);
    
    // Determine the width/height for each side
    CGFloat widthTop    = std::abs(bottomRightPoint.x - bottomLeftPoint.x);
    CGFloat widthBottom = std::abs(topRightPoint.x - topLeftPoint.x);
    CGFloat heightRight = std::abs(topRightPoint.y - bottomRightPoint.y);
    CGFloat heightLeft  = std::abs(topLeftPoint.y - bottomLeftPoint.y);
    
    // Determine the maximum width/height of the image
    CGFloat maxWidth    = (widthTop > widthBottom) ? widthTop : widthBottom;
    CGFloat maxHeight   = (heightRight > heightLeft) ? heightRight : heightLeft;
    
    // Source and desitination arrays
    cv::Point2f source[4], dest[4];
    
    // Set the source points
    source[0].x = topLeftPoint.x;
    source[0].y = topLeftPoint.y;
    source[1].x = topRightPoint.x;
    source[1].y = topRightPoint.y;
    source[2].x = bottomRightPoint.x;
    source[2].y = bottomRightPoint.y;
    source[3].x = bottomLeftPoint.x;
    source[3].y = bottomLeftPoint.y;
    
    // Set the destination points
    dest[0].x = 0;
    dest[0].y = 0;
    dest[1].x = maxWidth;
    dest[1].y = 0;
    dest[2].x = maxWidth;
    dest[2].y = maxHeight;
    dest[3].x = 0;
    dest[3].y = maxHeight;
    
    // Matrix to hold the transform
    cv::Mat transformed = cv::Mat(cvSize(maxWidth,maxHeight), CV_8UC1);
    
    // Get and apply the transformaion
    cv::warpPerspective(original, transformed, cv::getPerspectiveTransform(source, dest), cvSize(maxWidth, maxHeight));
    
    // Get the new image after transform
    UIImage * retImage = [self UIImageFromCVMatrix:transformed];
    
    // Release variables we're done with
    transformed.release();
    original.release();
    
    return retImage;
}

/**
 * Converts a UIImage to an OpenCV matrix
 *
 * Provided by OpenCV Documentation
 * URL: http://docs.opencv.org/2.4/doc/tutorials/ios/image_manipulation/image_manipulation.html
 */
+ (cv::Mat)cvMatrixFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

/**
 * Converts an OpenCV matrix to a UIImage
 *
 * Provided by OpenCV Documentation
 * URL: http://docs.opencv.org/2.4/doc/tutorials/ios/image_manipulation/image_manipulation.html
 */
+ (UIImage *)UIImageFromCVMatrix:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage * finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
