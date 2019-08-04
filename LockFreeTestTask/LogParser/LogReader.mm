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

- (void)addObservers;

@end

@implementation LogReader

- (nullable instancetype)init {
    if (self = [super init]) {
        //lamda to process process matched lines
        __weak typeof(self) _wself = self;
        auto callBack = [=](const char *linePtr) {
            NSString *string = [NSString stringWithCString:linePtr encoding:NSUTF8StringEncoding];
            [_delegate reader:_wself foundLines:string];
            return true;
        };
        
        _reader = new CLogReader(callBack);
        if (!_reader) {
            self = nil;
            return nil;
        }
        [self addObservers];

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

- (BOOL)addToParse:(NSData * _Nullable)part {
    return _reader->AddSourceBlock((const char *)part.bytes, part.length);
}

- (void)addObservers {
    [self addObserver:self forKeyPath:@"key" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ( [keyPath isEqualToString:@"key"] ) {
        NSString * key = change[NSKeyValueChangeNewKey];
        if (![key isKindOfClass:[NSNull class]] && !_reader->SetFilter(key.UTF8String)) {
            NSLog(@"Error!!! Parser. Couldn't set filter key");
            return;
        }
    }
}
@end
