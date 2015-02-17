//
//  UIImage+ORIENT.h
//  REPO
//
//  Created by Nate Peterson on 5/27/14.
//  Copyright (c) 2014 Jackson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ORIENT)

- (UIImage *)imageWithFixedOrientation:(BOOL)gallery;
- (UIImage *)crop:(CGRect)rect;

@end
