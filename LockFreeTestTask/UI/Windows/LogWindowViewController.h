//
//  LogWindowViewController.h
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 8/12/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol LogWindowDelegate <NSObject>
- (void) closeController:(UIViewController *)controller;
- (void) activatedSearchOnController:(UIViewController *)controller;
@end

@interface LogWindowViewController : UIViewController
@property (assign, nonatomic, getter=isCloseButtonHidden) BOOL closeButtonHidden;
@property (nullable, assign, nonatomic) id<LogWindowDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
