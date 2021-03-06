//
//  FileLoader.h
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 7/17/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LogDownloader;
@protocol LogDownloaderDelegate <NSObject>
- (void)loader:(LogDownloader * _Nonnull)loader contentLength:(NSUInteger)length;
- (void)loader:(LogDownloader * _Nonnull)loader loadedPart:(NSData *_Nullable)data;
- (void)loader:(LogDownloader * _Nonnull)loader completedWith:(NSError * _Nullable)error;
- (void)loader:(LogDownloader * _Nonnull)loader progress:(float)progress;
@end

@interface LogDownloader: NSObject
@property(assign, nonatomic) id<LogDownloaderDelegate> _Nullable delegate;
- (void)loadByUrl:(NSURL * _Nonnull )url;
- (void)cancel;
@end
