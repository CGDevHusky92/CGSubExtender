//
//  OpenCVMatrixTranslator.h
//  CGSubExtender
//
//  Created by Charles Gorectke on 11/18/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class CGCropImageView;

@interface CGOpenCVMatrixTranslator : NSObject

+ (UIImage *)cropImageView:(CGCropImageView *)imageView;

@end
