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

@interface ViewController () <LogDownloaderDelegate, LogReaderDelegate>

@property (weak, nonatomic) IBOutlet UITextField *urlEditor;
@property (weak, nonatomic) IBOutlet UITextField *filterEditor;
@property (weak, nonatomic) IBOutlet UITextView *searchResultView;
@property (weak, nonatomic) UIView *activityView;

//@property (weak, nonatomic) LogDownloader * loader;
@property (strong, nonatomic) LogReader * reader;

@property (copy, nonatomic) NSError * error;
@property (assign, nonatomic) BOOL inProgress;

- (IBAction)searchActivated:(id)sender;
@end

@implementation ViewController

- (void) dealloc {
//    self.loader = nil;
    self.error = nil;
    self.reader = nil;
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)]];
    [self addActivityIndicator];
    self.urlEditor.text = @"https://testlogstorage.s3.eu-north-1.amazonaws.com/access.log";//@"http://www.almhuette-raith.at/apache-log/access.log";
    [self addObservers];
    self.inProgress = NO;
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
    [self addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"inProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"error"]) {
        [self showError];
    }
    if ([keyPath isEqualToString:@"inProgress"]) {
        [self.activityView setHidden:![change[NSKeyValueChangeNewKey] boolValue]];
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
    self.reader = [LogReader readerWithContainerSize:length];
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

#pragma mark - LogReaderDelegate API
- (void)reader:(nullable LogReader *)reader foundLines:(nullable NSString *)lines {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString * logs = self.searchResultView.text != nil ? self.searchResultView.text: @"";
        NSMutableString * newLogs = [NSMutableString stringWithString:logs];
        [newLogs appendString: lines];
        self.searchResultView.text = newLogs;
    });
}

- (void)reader:(nullable LogReader *)reader completedWithError:(nullable NSError *)error {
    self.error = error;
    self.reader = nil;
}
@end
