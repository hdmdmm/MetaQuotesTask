//
//  Parser.h
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 7/22/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogDownloader.h"

@class LogReader;

@protocol LogReaderDelegate <NSObject>
- (void)reader:(nullable LogReader *)reader foundLines:(nullable NSString *)lines; //The string has all found lines that are separated by '\n'
- (void)reader:(nullable LogReader *)reader completedWithError:(nullable NSError *)error;
@end

@interface LogReader: NSObject

@property (copy, nonatomic) NSString * _Nullable key;
@property (assign, nonatomic) id<LogReaderDelegate> _Nullable delegate;

+ (nullable instancetype)readerWithContainerSize:(NSUInteger)length;
- (BOOL)addToParse:(nullable NSData *)part;

@end
