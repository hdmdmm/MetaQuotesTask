//
//  MainViewController.m
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 8/12/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import "MainViewController.h"
#import "LogWindowViewController.h"

typedef enum : NSUInteger {
    StepForward = 1,
    StepBack = -1
} Step;

@interface MainViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) NSMutableArray *logControllers;
@end

@interface MainViewController(LogWindow) <LogWindowDelegate>
@end

@implementation MainViewController

- (void)dealloc {
    self.logControllers = nil;
    self.pageController = nil;
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializePageController];
}

- (void)initializePageController {
    self.pageController = [[[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil] autorelease];
    self.pageController.dataSource = self;
    
    //create controllers
    UIViewController *initialController = [self createLogViewController];
    self.logControllers = [NSMutableArray arrayWithObject:initialController];
    [self setCurrentViewController:initialController];
    
    //add page controller as child
    [self addChildViewController:self.pageController];
    [self.view addSubview: self.pageController.view];
    [self.pageController didMoveToParentViewController:self];
    
    //setup constraints
    [self.pageController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
    [[self.pageController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor] setActive:YES];
    [[self.pageController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor] setActive:YES];
    [[self.pageController.view.leftAnchor constraintEqualToAnchor:self.view.leftAnchor] setActive:YES];
    [[self.pageController.view.rightAnchor constraintEqualToAnchor:self.view.rightAnchor] setActive:YES];
}

- (nullable LogWindowViewController *)next:(NSInteger)direction ofController:(UIViewController *)viewController {
    NSUInteger index = [self.logControllers indexOfObject:viewController] + direction;
    NSUInteger count = [self.logControllers count];
    if (index < count) {
        return [self.logControllers objectAtIndex:index];
    }
    return nil;
}

- (nonnull LogWindowViewController *)createLogViewController{
    UIStoryboard *stb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LogWindowViewController *vc = [stb instantiateViewControllerWithIdentifier: @"LogWindowViewController"];
    vc.delegate = self;
    return vc;
}

- (void)setCurrentViewController:(nonnull UIViewController *)controller {
    [self.pageController setViewControllers:@[controller]
                                  direction:UIPageViewControllerNavigationDirectionForward
                                   animated:NO completion:nil];
}

- (void)hideCloseButtonOnController:(UIViewController *) controller {
    if ([controller isKindOfClass:[LogWindowViewController class]]) {
        ((LogWindowViewController *)controller).closeButtonHidden = [self.logControllers indexOfObject:controller] == 0;
    }
}

- (UIViewController *)viewControllerBy:(Step)step of:(UIViewController *)controller {
    LogWindowViewController * vc = [self next:step ofController:controller];
    [self hideCloseButtonOnController:vc];
    [self hideCloseButtonOnController:controller];
    return vc;
}

#pragma mark - UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    
    return [self viewControllerBy:StepForward of:viewController];
}
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    
    return [self viewControllerBy:StepBack of:viewController];
}
@end


@implementation MainViewController(LogWindow)
- (void) closeController:(UIViewController *)controller {

    UIViewController * vc = [self next:StepForward ofController:controller];
    if (vc == NULL) {
        vc = [self next:StepBack ofController:controller];
    }
    if (vc != NULL) {
        [self.logControllers removeObject:controller];
        [self setCurrentViewController:vc];
        return;
    }
}

- (void) activatedSearchOnController:(UIViewController *)controller {
    if ([self next:StepForward ofController:controller] == NULL) {
        [self.logControllers addObject:[self createLogViewController]];
        [self setCurrentViewController:controller];
    }
}

@end
