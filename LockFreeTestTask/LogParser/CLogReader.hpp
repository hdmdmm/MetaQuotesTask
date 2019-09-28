//
//  CLogReader.hpp
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 7/17/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#ifndef CLogReader_hpp
#define CLogReader_hpp

#include <stdio.h>
#include <functional>
#import <pthread.h>

#include "BlockInfo.hpp"

using namespace std;

class CLogReader final {
private:
    char *_search_key;
    int _thread_counter;
    
    mutable char *_appendix;
    mutable pthread_mutex_t _mutex;

private:
    bool LaunchThread(BlockInfo *info);
    function<void(const char *)> call_back;
    function<void(void)> end_call_back;
    void Cleanup();

public:
    CLogReader( function<void(const char *)> call_back, function<void(void)> end_call_back );
    ~CLogReader();
    /**
     */
    // установка фильтра строк, false - ошибка
    bool SetFilter(const char *filter);
    // добавление очередного блока текстового файла
    bool AddSourceBlock(const char *block, const size_t block_size);

public:
    const char *GetFilter() const;
    const char *GetAppendix() const;
    void CleanupAppendix() const;
    bool SetAppendix(const char *end_line) const;
    
    void LockThreads() const;
    void UnlockThreads() const;
    int NumberOfThreads() const;
    
    void FoundResult(const char *line) const;
    void EndReading() const;
};
#endif /* CLogReader_hpp */
