//
//  ViewController.m
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 8/19/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import "ViewController.h"

typedef NS_ENUM(NSUInteger, ViewTag) {
    ViewTagActivity = 1000
};

@implementation UIViewController (LockFreeTestTask)

- (UIView *)addActivityIndicator {
    //Create background view with transparency
    UIView * view = [[[UIView alloc] initWithFrame:CGRectNull] autorelease];
    [view setTag:ViewTagActivity];
    [self.view addSubview: view];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [[view.topAnchor constraintEqualToAnchor: self.view.topAnchor] setActive:YES];
    [[view.bottomAnchor constraintEqualToAnchor: self.view.bottomAnchor] setActive:YES];
    [[view.leadingAnchor constraintEqualToAnchor: self.view.leadingAnchor] setActive:YES];
    [[view.trailingAnchor constraintEqualToAnchor: self.view.trailingAnchor] setActive:YES];
    view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    
    //Create activity indicator
    UIActivityIndicatorView * indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:indicator];
    [indicator startAnimating];
    [[indicator.centerXAnchor constraintEqualToAnchor:view.centerXAnchor] setActive:YES];
    [[indicator.centerYAnchor constraintEqualToAnchor:view.centerYAnchor] setActive:YES];
    return view;
}

- (void)setHiddenActivityIndicator:(BOOL)isHidden {
    UIView *activityView = [self.view viewWithTag:ViewTagActivity];
    if (activityView == NULL) {
        activityView = [self addActivityIndicator];
    }
    [activityView setHidden:isHidden];
}

@end
