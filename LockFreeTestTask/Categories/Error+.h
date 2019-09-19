//
//  Error+.h
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 8/19/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AppError) {
    LockFreeErrorInputFields = -1000
};

@interface NSError(LockFreeTestTask)
+ (NSError *)errorWithCode:(AppError)code;
@end

NS_ASSUME_NONNULL_END
