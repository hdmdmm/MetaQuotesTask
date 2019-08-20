//
//  LogWindowViewController.m
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 8/12/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import "LogWindowViewController.h"
#import "ViewController+.h"
#import "Error+.h"
#import "LogReader.h"

#define MAX_UPDATE_COUNTER 10

@interface LogWindowViewController () <LogDownloaderDelegate, LogReaderDelegate> {
    dispatch_queue_t _queue;
}
//
@property (strong, nonatomic) LogReader *reader;
@property (strong, nonatomic) LogDownloader *loader;

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
@property (assign, nonatomic) BOOL isResultReady;
@property (strong, nonatomic) NSError *error;

//model
@property (strong, nonatomic) NSMutableString *model;
@end

@implementation LogWindowViewController {
    NSInteger _counter;
}

- (void)dealloc {
    [self removeObservers];
    self.error = nil;
    self.model = nil;
    self.loader = nil;
    self.reader = nil;
    dispatch_release(_queue);
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.closeButtonHidden = YES;
    // Do any additional setup after loading the view from its nib.
    [self localize];
    [self setupButtons];
    [self addObservers];
    
    [self.view addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)]];
    self.urlEditor.text = @"https://testlogstorage.s3.eu-north-1.amazonaws.com/access.log";
    
    _queue = dispatch_queue_create("com.hdmdmm.lockfreetesttask.outputqueue", DISPATCH_QUEUE_SERIAL);
}

- (void)localize {
    self.urlEditor.placeholder = NSLocalizedString(self.urlEditor.placeholder, nil);
    self.filterEditor.placeholder = NSLocalizedString(self.filterEditor.placeholder, nil);
    [self.searchButton setTitle:NSLocalizedString(self.searchButton.currentTitle, nil) forState:UIControlStateNormal];
}

- (void)setupButtons {
    UIImage *closeImage = [[self.closeButton currentImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.closeButton setImage:closeImage forState:UIControlStateNormal];
    [self.closeLogViewButton setImage:closeImage forState:UIControlStateNormal];
}

- (void)startLoading {
    self.model = [NSMutableString string];
    self.loader = [[LogDownloader new] autorelease];
    [self.loader setDelegate:self];
    [self.loader loadByUrl:[NSURL URLWithString:self.urlEditor.text]];
    self.inProgress = YES;
    self.isResultReady = NO;
    _counter = MAX_UPDATE_COUNTER;
}

// actions
#pragma mark - Actions
- (void)hideKeyboard:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)activatedSearch:(UIButton *)sender {
    if ([self.urlEditor.text length] == 0
        || [self.filterEditor.text length] == 0){
        self.error = [NSError errorWithCode:LockFreeErrorInputFields];
        return;
    }
    if (_delegate) {
        [_delegate activatedSearchOnController:self];
    }
    [self.view endEditing:YES];
    self.textView.text = nil;
    [self startLoading];
}

- (IBAction)activatedClose:(UIButton *)sender {
    if (_delegate) {
        [_delegate closeController:self];
    }
}

- (IBAction)activatedResultScreenClose:(id)sender {
    [self.loader cancel];
    self.loader = nil;
    [self.reader cancel];
    self.reader = nil;
    [self.logView setHidden:YES];
}

- (void)setCloseButtonHidden:(BOOL)hidden {
    _closeButtonHidden = hidden;
    [self.closeButton setHidden:hidden];
}

#pragma mark -Observers
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
        [self setHiddenActivityIndicator:![change[NSKeyValueChangeNewKey] boolValue]];
    }
    if ([keyPath isEqualToString:@"isResultReady"]) {
        [self.logView setHidden:![change[NSKeyValueChangeNewKey] boolValue]];
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
    self.loader = nil;
}

- (void)loader:(LogDownloader * _Nonnull)loader progress:(float)progress {
    [self.progressView setProgress:progress];
    [self.progressLabel setText:[NSString stringWithFormat:@"%.02f%s", progress*100, "%"]];
}

#pragma mark - LogReaderDelegate API
- (void)reader:(nullable LogReader *)reader foundLines:(nullable NSString *)lines {
    if (lines == nil) return;
    __weak typeof (self) wself = self;
    dispatch_async(_queue, ^{
        [wself.model appendString:lines];
        [wself.model appendString:@"\n"];
        [wself.model appendString:@"\n"];
        if (0 < _counter--) return;
        _counter = MAX_UPDATE_COUNTER;
        dispatch_async(dispatch_get_main_queue(), ^{
            wself.textView.text = wself.model;
            if (wself.inProgress == YES)
                wself.inProgress = NO;
            if (wself.isResultReady == NO)
                wself.isResultReady = YES;
        });
    });
}

- (void)reader:(nullable LogReader *)reader completedWithError:(nullable NSError *)error {
    self.error = error;
    self.reader = nil;
}
@end
