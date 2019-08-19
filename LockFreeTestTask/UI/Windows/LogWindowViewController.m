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
    [self removeObservers];
    self.error = nil;
    self.model = nil;
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.closeButtonHidden = YES;
    // Do any additional setup after loading the view from its nib.
    [self localize];
    [self addObservers];
}

- (void)localize {
    self.urlEditor.placeholder = NSLocalizedString(self.urlEditor.placeholder, nil);
    self.filterEditor.placeholder = NSLocalizedString(self.filterEditor.placeholder, nil);
    [self.searchButton setTitle:NSLocalizedString(self.searchButton.currentTitle, nil) forState:UIControlStateNormal];
}

// actions
- (IBAction)activatedSearch:(UIButton *)sender {
    if ([self.urlEditor.text length] == 0
        || [self.filterEditor.text length] == 0){
        self.error = [NSError errorWithDomain:@"com.hdmdmm.LockFreeTestTask.LogWindow"
                                         code:-1000 ///TODO: to enumerate all errors
                                     userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"err_message_empty_fields", nil)}];
        return;
    }
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

#pragma mark -Observers
- (void)addObservers {
    [self addObserver:self forKeyPath:@"error"
              options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObservers {
    [self removeObserver:self forKeyPath:@"error"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"error"]) {
        [self showError];
    }
}

- (void)showError {
    if (self.error != NULL) {
        self.inProgress = NO;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error!!!" message:self.error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction: [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        self.error = nil;
    }
}
@end
