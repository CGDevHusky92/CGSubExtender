//
//  UIImage+ORIENT.h
//  REPO
//
//  Created by Nate Peterson on 5/27/14.
//  Copyright (c) 2014 Jackson. All rights reserved.
//

#import "UIImage+ORIENT.h"

CGFloat DegreesToRadians(CGFloat degrees) { return degrees * M_PI / 180; };
CGFloat RadiansToDegrees(CGFloat radians) { return radians * 180/M_PI;   };

@implementation UIImage (ORIENT)

- (UIImage *)imageWithFixedOrientation
{
    UIImage *image = self;

    // Chase to the rescue:
    
    CGSize imgSize = [image size];
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,imgSize.height, imgSize.width)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(90));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    rotatedViewBox = nil;

    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();

    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);

    switch ([image imageOrientation]) {
        case UIImageOrientationUp:
            NSLog(@"Image Orientation Up");
            break;
        case UIImageOrientationDown:
            NSLog(@"Image Orientation Down");
            CGContextRotateCTM(bitmap, DegreesToRadians(180));
            break;
        case UIImageOrientationLeft:
            NSLog(@"Image Orientation Left");
            CGContextRotateCTM(bitmap, DegreesToRadians(-90));
            break;
        case UIImageOrientationRight:
            // Rotate the image context
            NSLog(@"Image Orientation Right");
            CGContextRotateCTM(bitmap, DegreesToRadians(90));
            break;
        default:
            NSLog(@"No Orientation Detected");
            break;
    }

    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-imgSize.height / 2, -imgSize.width / 2, imgSize.height, imgSize.width), [image CGImage]);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)crop:(CGRect)rect
{
    rect = CGRectMake(rect.origin.x*self.scale,
                      rect.origin.y*self.scale,
                      rect.size.width*self.scale,
                      rect.size.height*self.scale);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef
                                          scale:self.scale
                                    orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

@end
