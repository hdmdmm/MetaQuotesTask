//
//  ViewController.m
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 7/16/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import "ViewController.h"
#import "LogDownloader.h"
#import "LogReader.h"

@interface ViewController () <LogDownloaderDelegate, LogReaderDelegate> {
    dispatch_queue_t _queue;
}

@property (weak, nonatomic) IBOutlet UITextField *urlEditor;
@property (weak, nonatomic) IBOutlet UITextField *filterEditor;
@property (weak, nonatomic) IBOutlet UITextView *searchResultView;
@property (weak, nonatomic) UIView *activityView;
@property (weak, nonatomic) IBOutlet UIView *resultWindow;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIButton *activityButton;

//@property (weak, nonatomic) LogDownloader * loader;
@property (strong, nonatomic) LogReader * reader;
@property (copy, nonatomic) NSError * error;
@property (assign, nonatomic) BOOL inProgress;
@property (assign, nonatomic) BOOL isResultReady;
@property (strong, nonatomic) NSMutableString *matchedLog;

- (IBAction)searchActivated:(id)sender;
@end

@implementation ViewController

- (void) dealloc {
//    self.loader = nil;
    dispatch_release(_queue);
    self.error = nil;
    self.reader = nil;
    self.matchedLog = nil;
    [self removeObservers];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self localize];
     _queue = dispatch_queue_create("com.hdmdmm.lockfreetesttask.outputqueue", DISPATCH_QUEUE_SERIAL);
    [self.view addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)]];
    [self addActivityIndicator];
    self.urlEditor.text = @"https://testlogstorage.s3.eu-north-1.amazonaws.com/access.log";
    //@"http://www.almhuette-raith.at/apache-log/access.log";
    self.matchedLog = [NSMutableString stringWithString:@"Search result:\n"];
    [self addObservers];
    self.inProgress = NO;
    self.isResultReady = NO;
}

- (void)localize {
    self.urlEditor.placeholder = NSLocalizedString(self.urlEditor.placeholder, nil);
    self.filterEditor.placeholder = NSLocalizedString(self.filterEditor.placeholder, nil);
    [self.activityButton setTitle:NSLocalizedString(self.activityButton.currentTitle, nil) forState:UIControlStateNormal];
}

- (IBAction)searchActivated:(id)sender {
    [self.view endEditing:YES];
    self.searchResultView.text = nil;
    [self startLoading];
}

- (void)hideKeyboard:(id)sender {
    [self.view endEditing:YES];
}

- (void)addActivityIndicator {
    //Create background view with transparency
    UIView * view = [[[UIView alloc] initWithFrame:CGRectNull] autorelease];
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
    self.activityView = view;
}

- (void)startLoading {
    LogDownloader *loader = [LogDownloader new];
    [loader setDelegate:self];
    [loader loadByUrl:[NSURL URLWithString:self.urlEditor.text]];
    self.inProgress = YES;
}

- (void)addObservers {
    [self addObserver:self forKeyPath:@"error"
              options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"inProgress"
              options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"isResultReady"
              options:NSKeyValueObservingOptionNew context:nil];
}
- (void)removeObservers {
    [self removeObserver:self forKeyPath:@"error"];
    [self removeObserver:self forKeyPath:@"inProgress"];
    [self removeObserver:self forKeyPath:@"isResultReady"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"error"]) {
        [self showError];
    }
    if ([keyPath isEqualToString:@"inProgress"]) {
        [self.activityView setHidden:![change[NSKeyValueChangeNewKey] boolValue]];
    }
    if ([keyPath isEqualToString:@"isResultReady"]) {
        [self.resultWindow setHidden:![change[NSKeyValueChangeNewKey] boolValue]];
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

#pragma mark - LogDownloaderDelegate API
- (void)loader:(LogDownloader * _Nonnull)loader contentLength:(NSUInteger)length {
    self.reader = nil;
    self.reader = [[LogReader new] autorelease];
    self.reader.delegate = self;
    self.reader.key = self.filterEditor.text;
}

- (void)loader:(LogDownloader * _Nonnull)loader loadedPart:(NSData *_Nullable)data {
    [self.reader addToParse:data];
}

- (void)loader:(LogDownloader * _Nonnull)loader completedWith:(NSError * _Nullable)error {
    self.error = error;
    [loader release];
}

- (void)loader:(LogDownloader * _Nonnull)loader progress:(float)progress {
    [self.progressView setProgress:progress];
    [self.progressLabel setText:[NSString stringWithFormat:@"%.02f%s", progress*100, "%"]];
}

#pragma mark - LogReaderDelegate API
- (void)reader:(nullable LogReader *)reader foundLines:(nullable NSString *)lines {
    if (lines == nil) return;
    
    dispatch_async(_queue, ^{
        [self.matchedLog appendString:lines];
        [self.matchedLog appendString:@"\n"];
        [self.matchedLog appendString:@"\n"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.searchResultView.text = self.matchedLog;
            self.inProgress = NO;
            self.isResultReady = YES;
        });
    });
}

- (void)reader:(nullable LogReader *)reader completedWithError:(nullable NSError *)error {
    self.error = error;
    self.reader = nil;
}
@end
