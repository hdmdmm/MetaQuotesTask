//
//  FileLoader.m
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 7/17/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import "LogDownloader.h"
#define MAX_BUFFER_SIZE 1024*1000*2
@interface LogDownloader() <NSURLSessionDataDelegate> {
    NSUInteger _receivedBytes;
    NSUInteger _contentLength;
}
@property (retain, nonatomic) NSURLSession *session;
@property (retain, nonatomic) NSMutableData *buffer;
@end

@implementation LogDownloader
- (instancetype)init {
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 20;
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        self.buffer = [NSMutableData dataWithCapacity:MAX_BUFFER_SIZE];
    }
    return self;
}

- (void)dealloc {
    self.buffer = nil;
    [self.session finishTasksAndInvalidate];
    self.session = nil;
    [super dealloc];
}

- (void)loadByUrl:(NSURL*)url {
    [[_session dataTaskWithURL:url] resume];
}

- (void)cancel {
    [_session invalidateAndCancel];
}

#pragma mark - NSURLSessionDataDelegate API

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response
completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    _contentLength = [[[(NSHTTPURLResponse *)response allHeaderFields] valueForKey:@"Content-Length"] integerValue];
    completionHandler( _receivedBytes == _contentLength ? NSURLSessionResponseCancel : NSURLSessionResponseAllow );
    [self.delegate loader:self contentLength:_contentLength];
    NSLog(@"\nContent-length: %ld\nReceived-bytes: %ld", (long)_contentLength, (long)_receivedBytes);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    _receivedBytes += data.length;
    NSLog(@"\nReceived package: %ld bytes", (long)data.length );
    float progress = (float)_receivedBytes/(float)_contentLength;
    [self.delegate loader:self progress:progress];
    // store received data to buffer
    [self.buffer appendData:data];
    //check for discharge of buffer
    if (self.buffer.length > MAX_BUFFER_SIZE - 1024*16) { // -16Kb
        [self deliverLoadedData];
    }
}

- (void)deliverLoadedData {
    __block NSData *buffer = [self.buffer retain];//
    __block __weak typeof(self) _weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_delegate loader:_weakSelf loadedPart:buffer];
        [buffer release];
    });
    // create new buffer
    self.buffer = [NSMutableData dataWithCapacity:MAX_BUFFER_SIZE];
}
#pragma mark - NSURLSessionDelegate API
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    [self.delegate loader:self completedWith:error];
}

#pragma mark - NSURLSessionTaskDelegate API
- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    [self.delegate loader:self completedWith:error];
    NSLog(@"\nReceived log file: %ld", (long)_receivedBytes );
}

@end

