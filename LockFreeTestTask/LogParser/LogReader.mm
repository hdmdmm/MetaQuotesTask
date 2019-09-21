//
//  Parser.m
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 7/22/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import "LogReader.h"
#import "CLogReader.hpp"

@interface LogReader() {
    CLogReader * _reader;
}

@end

@implementation LogReader

- (nullable instancetype)init {
    if (self = [super init]) {
        
        //lamda to process process matched lines
        __weak typeof(self) _wself = self;
        auto callBack = [=](const char *linePtr) {
            NSString *string = [NSString stringWithCString:linePtr encoding:NSUTF8StringEncoding];
            [_delegate reader:_wself foundLine:string];
            return true;
        };
        auto endCallBack = [=](void) {
            [_delegate reader:_wself completedWithError:nil];
        };
        
        _reader = new CLogReader( callBack, endCallBack );
        if (!_reader) {
            [self release];
            return nil;
        }

    }
    return self;
}

- (void)dealloc {
    if (_reader) {
        delete _reader;
        _reader = NULL;
    }
    self.key = nil;
    [super dealloc];
}

- (void)cancel {
    //manage by all created threads
    self.delegate = nil;
}

- (BOOL)addToParse:(NSData * _Nullable)part {
    return _reader->AddSourceBlock((const char *)part.bytes, part.length);
}

- (void)setKey:(NSString *)key {
    if (![key isKindOfClass:[NSNull class]]
        && _reader != NULL
        && !_reader->SetFilter(key.UTF8String)) {
        
        NSLog(@"Error!!! Parser. Couldn't set filter key");
        return;
    }
}

@end
