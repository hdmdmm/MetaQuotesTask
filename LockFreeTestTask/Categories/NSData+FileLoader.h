//
//  NSData.h
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 7/16/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface NSData(FileLoader)
+ (instancetype) loadFile: (NSString*)url error: (NSError **)error;
@end
