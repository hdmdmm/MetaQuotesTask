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

@interface LogWindowViewController () <LogDownloaderDelegate, LogReaderDelegate>
//services
@property (strong, nonatomic) LogReader *reader;
@property (strong, nonatomic) LogDownloader *loader;

//input fields
@property (weak, nonatomic) IBOutlet UITextField *urlEditor;
@property (weak, nonatomic) IBOutlet UITextField *filterEditor;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

//result view
@property (weak, nonatomic) IBOutlet UIView *logView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeLogViewButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

//states
@property (assign, nonatomic) BOOL inProgress;
@property (assign, nonatomic) BOOL isResultReady;
@property (strong, nonatomic) NSError *error;

//model
@property (strong, nonatomic) NSString *logFileName;

@property (strong, nonatomic) NSMutableArray<NSString *> *models;
@end

@implementation LogWindowViewController

- (void)dealloc {
    self.error = nil;
    self.loader = nil;
    self.reader = nil;
    self.logFileName = nil;
    self.models = nil;
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.closeButtonHidden = YES;
    // Do any additional setup after loading the view from its nib.
    [self localize];
    [self setupButtons];

    [self.view addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)]];
    self.urlEditor.text = @"https://testlogstorage.s3.eu-north-1.amazonaws.com/access.log";
    
    self.models = [NSMutableArray arrayWithCapacity:20];
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
    self.loader = [[LogDownloader new] autorelease];
    [self.loader setDelegate:self];
    [self.loader loadByUrl:[NSURL URLWithString:self.urlEditor.text]];
    self.inProgress = YES;
    self.isResultReady = NO;
    self.logFileName = [self pathToLogFile];
    [self cleanupLogFile];
}

// actions
#pragma mark - Actions
- (void)hideKeyboard:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)activatedSearch:(UIButton *)sender {
    if ([self.urlEditor.text length] == 0
        || [self.filterEditor.text length] == 0){
        self.error = [NSError errorWithCode:AppErrorInputFields];
        return;
    }
    if (_delegate) {
        [_delegate activatedSearchOnController:self];
    }
    [self.view endEditing:YES];

    [self.models removeAllObjects];

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
    self.isResultReady = NO;
}

- (void)setCloseButtonHidden:(BOOL)hidden {
    _closeButtonHidden = hidden;
    [self.closeButton setHidden:hidden];
}

#pragma mark -Observers
- (void)setError:(NSError *)error {
    [self showError:error];
}

- (void)setInProgress:(BOOL)inProgress {
    [self setHiddenActivityIndicator:!inProgress];
}

- (void)setIsResultReady:(BOOL)isResultReady {
    [self.logView setHidden:!isResultReady];
}

#pragma mark -Helpers
- (NSString *)pathToLogFile {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logFilePath = [documentPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%@_results", self.filterEditor.text] ];
    logFilePath = [logFilePath stringByAppendingPathExtension:@"log"];
    return logFilePath;
}

- (void)showError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            self.inProgress = NO;
            UIAlertController *alert
            = [UIAlertController alertControllerWithTitle: @"Ups... :)"
                                                  message: error.localizedDescription
                                           preferredStyle: UIAlertControllerStyleAlert];
            [alert addAction: [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController: alert animated:YES completion:nil];
            self.error = nil;
        }
    });
}

- (void)updateLogView {
    __weak typeof (self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself.tableView reloadData];
        wself.inProgress = NO;
        wself.isResultReady = YES;
    });
}

- (void)saveToLogFile:(nullable NSString*)lines {
    NSError *error = nil;
    if (![lines writeToFile:self.logFileName atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        NSLog(@"Couldn't write lines to file %@\nError = %@", self.logFileName, error);
    }
}

- (void)cleanupLogFile {
    if (!self.logFileName || [self.logFileName length] == 0 )
        return;
    
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm removeItemAtPath:self.logFileName error:&error]) {
        NSLog(@"Couldn't remove file %@ (%@)", error, self.logFileName);
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
- (void)reader:(nullable LogReader *)reader foundLine:(nullable NSString *)line {
    if (line == nil) return;

    [self.models addObject:line];
    [self saveToLogFile:line];

    if ([self.models count] % 20 == 0)
        [self updateLogView];
}

- (void)reader:(nullable LogReader *)reader completedWithError:(nullable NSError *)error {
 
    // completion handler can be called after processed last block
    // but loader still is getting next block of data
    if (self.loader != nil) {
        return;
    }

    // state when loader finished downloading and released
    // show error if log reader didn't find any result
    if (self.models.count == 0) {
        self.error = [NSError errorWithCode:AppErrorNoResults];
        self.reader = nil;
        return;
    }

    // update last parsed results
    [self updateLogView];
}
@end



@interface LogWindowViewController(TableView) <UITableViewDelegate, UITableViewDataSource>
@end

@implementation LogWindowViewController(TableView)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogLineCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LogLineCell"];
    }
    cell.textLabel.text = self.models[indexPath.row];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [[UIColor greenColor] colorWithAlphaComponent:.85];
    cell.textLabel.numberOfLines = 0;
    return cell;
}

@end
