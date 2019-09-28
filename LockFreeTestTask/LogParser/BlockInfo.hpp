//
//  BlockInfo.h
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 9/28/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#ifndef BlockInfo_h
#define BlockInfo_h

class CLogReader;

typedef struct BlockInfo {
    const char * data;
    const CLogReader *reader;
    size_t size;
    int thread_counter = 0;

    void free() {
        ::free((void *)data);
        ::free(this);
    }
} BlockInfo;


#endif /* BlockInfo_h */
