//
//  FileLoader.m
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 7/17/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import "LogDownloader.h"
@interface LogDownloader() <NSURLSessionDataDelegate> {
    NSUInteger receivedBytes;
    NSUInteger contentLength;
}
@property (retain, nonatomic) NSURLSession * session;
@end

@implementation LogDownloader
- (instancetype)init {
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 10;
//        config.timeoutIntervalForResource = 10;
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (void)dealloc {
    [_session finishTasksAndInvalidate];
    [_session release];
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
    
    contentLength = [[[(NSHTTPURLResponse *)response allHeaderFields] valueForKey:@"Content-Length"] integerValue];
    completionHandler( receivedBytes == contentLength ? NSURLSessionResponseCancel : NSURLSessionResponseAllow );
    [self.delegate loader:self contentLength:contentLength];
    NSLog(@"\nContent-length: %ld\nReceived-bytes: %ld", (long)contentLength, (long)receivedBytes);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    receivedBytes += data.length;
    NSLog(@"\nReceived package: %ld bytes", (long)data.length );
    [self.delegate loader:self loadedPart:data];
    float progress = (float)receivedBytes/(float)contentLength;
    [self.delegate loader:self progress:progress];
}

#pragma mark - NSURLSessionDelegate API
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    [self.delegate loader:self completedWith:error];
}

#pragma mark - NSURLSessionTaskDelegate API
- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    [self.delegate loader:self completedWith:error];
    NSLog(@"\nReceived log file: %ld", (long)receivedBytes );
}

@end

