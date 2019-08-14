//
//  LogWindowViewController.m
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 8/12/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import "LogWindowViewController.h"

@interface LogWindowViewController ()
//


//input fields
@property (weak, nonatomic) IBOutlet UITextField *urlEditor;
@property (weak, nonatomic) IBOutlet UITextField *filterEditor;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

//result view
@property (weak, nonatomic) IBOutlet UIView *logView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *closeLogViewButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

//states
@property (assign, nonatomic) BOOL inProgress;
@property (strong, nonatomic) NSError *error;

//model
@property (strong, nonatomic) NSMutableArray *model;
@end

@implementation LogWindowViewController

- (void)dealloc {
    self.error = nil;
    self.model = nil;
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.closeButtonHidden = YES;
    // Do any additional setup after loading the view from its nib.
}

// actions
- (IBAction)activatedSearch:(UIButton *)sender {
    if (_delegate) {
        [_delegate activatedSearchOnController:self];
    }
}

- (IBAction)activatedClose:(UIButton *)sender {
    if (_delegate) {
        [_delegate closeController:self];
    }
}

- (void)setCloseButtonHidden:(BOOL)hidden {
    _closeButtonHidden = hidden;
    [self.closeButton setHidden:hidden];
}
@end
