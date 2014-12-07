//
//  CGSearchDisplayController.m
//  REPO
//
//  Created by Charles Gorectke on 7/16/14.
//  Copyright (c) 2014 Jackson. All rights reserved.
//

#import "CGSearchDisplayController.h"

@interface CGSearchDisplayController ()

@end

@implementation CGSearchDisplayController

- (void)setActive:(BOOL)visible animated:(BOOL)animated
{
    if (self.active == visible) return;
    [self.searchContentsController.navigationController setNavigationBarHidden:YES animated:NO];
    [super setActive:visible animated:animated];
    [self.searchContentsController.navigationController setNavigationBarHidden:NO animated:NO];
    
    if (visible) {
        [self.searchBar becomeFirstResponder];
    } else {
        [self.searchBar resignFirstResponder];
    }
}

@end
