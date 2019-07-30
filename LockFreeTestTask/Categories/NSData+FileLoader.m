//
//  NSData.m
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 7/16/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import "NSData+FileLoader.h"

@implementation NSData(FileLoader)
+ (instancetype) loadFile: (NSString*)urlString error: (NSError **)error {
    NSURL * url = [NSURL URLWithString: urlString];
    return [[[NSData alloc] initWithContentsOfURL:url options:NSDataReadingUncached error:error] autorelease];
}
@end
