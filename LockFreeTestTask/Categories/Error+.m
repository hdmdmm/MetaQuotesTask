//
//  Error+.m
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 8/19/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#import "Error+.h"

static NSString *domain = @"com.hdmdmm.LockFreeTestTask.Errors";

@implementation NSError(LockFreeTestTask)
+ (NSError *)errorWithCode:(AppError)code {
    NSString * localizedString = @"";
    switch (code) {
        case AppErrorInputFields:
            localizedString = NSLocalizedString(@"err_message_empty_fields", nil);
            break;
            
        case AppErrorNoResults:
            localizedString = NSLocalizedString(@"err_message_no_result", nil);
            break;
            
        default:
            localizedString = NSLocalizedString(@"err_message_generic", nil);
            break;
    }
    return [NSError errorWithDomain:domain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: localizedString}];
}
@end
