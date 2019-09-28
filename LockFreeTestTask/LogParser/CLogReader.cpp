//
//  CLogReader.cpp
//  LockFreeTestTask
//
//  Created by Dmitry Khotyanovich on 7/17/19.
//  Copyright © 2019 hdmdmm. All rights reserved.
//

#include "CLogReader.hpp"
#include <stdlib.h>
#include <string.h>
#import <pthread.h>
#include <unistd.h>

namespace api {
    // * - match to any symbols with any length
    // ? - match to any symbols. one symbol only.
    bool IsLineMatchToKey(const char * line, const char * key) {
        // Written by Jack Handy - <A href="mailto:jakkhandy@hotmail.com">jakkhandy@hotmail.com</A>
        const char *cp = NULL, *mp = NULL;

        while ((*line) && (*key != '*')) {
            if ((*key != *line) && (*key != '?')) {
                return 0;
            }
            key++;
            line++;
        }

        while (*line) {
            if (*key == '*') {
                if (!*++key) {
                    return 1;
                }
                mp = key;
                cp = line+1;
            } else if ((*key == *line) || (*key == '?')) {
                key++;
                line++;
            } else {
                key = mp;
                line = cp++;
            }
        }

        return !*key;
    }
    
//    void SaveAppendix(const char* appendix) {
//        if (!appendix) return;
//        size_t size_last_line = strlen(appendix);
//        if ( size_last_line && vars::appendix == NULL )
//            vars::appendix = strdup(appendix);
//    }

    void *FindMatchesInLines(void *arg) {
        BlockInfo * info = (BlockInfo *)arg;

        const CLogReader *reader = info->reader;
        if (!reader) { return NULL; } // it doesn't make sence continue here

        
        reader->LockThreads();
        printf("Started thread number %d\n", info->thread_counter);
        
        // getting appendix_size if it stored from previous block
        // the urlsession loads log file by short parts. Every part might finish not by '\n'.
        // In this case previous part contains not completed line and next part begins from final previous part of line.
        char *buffer = NULL;
        const char *appendix = reader->GetAppendix();
        if (appendix)
        {/// I really don't understand why but works for me based on memory api: memcpy, malloc
         /// I tryed strcat - smth going with memory
            size_t appendix_size = strlen(appendix);
            size_t size = appendix_size + info->size;
            buffer = (char*)malloc(size +1);
            memcpy(buffer, appendix, appendix_size);
            memcpy(buffer + appendix_size, info->data, info->size);
            buffer[size] = '\0';
            
            reader->CleanupAppendix();
        }
        
        // search for lines in the buffer
        // strtok, strsep are not works for me. smth going with memory. can't free allocated buffer
        // current solution works for me as well.
        char *block = buffer == NULL ? (char *)info->data : buffer;
        while (*block=='\n') block++;
        char *line_ptr = block;
        while (*block++) {
            if (*block == '\n') {
                block++;
                if (*block == '\0') {
                    line_ptr = NULL;
                    break;
                }
                size_t line_size = block-line_ptr;
                char *copied_line = strndup(line_ptr, line_size-1);
                if (IsLineMatchToKey(copied_line, reader->GetFilter())) {
                    reader->FoundResult(copied_line);
                }
                //
                line_ptr = block;
                free(copied_line);
            }
        }

        // store appendix if last line is not completed end line sign \n.
        reader->SetAppendix(line_ptr);
//        SaveAppendix(line_ptr);
        
        if (buffer != NULL)
            free(buffer);

        //free memory
        int thread_number = info->thread_counter;
        info->free();
        
        reader->UnlockThreads();
        printf("Finished thread number %d\n", thread_number);
        
        //marker of last created thread
        if (thread_number == reader->NumberOfThreads()) {
            reader->EndReading();
        }
        return NULL;
    }
}

CLogReader::CLogReader(function<void(const char *)> call_back, function<void(void)> end_call_back)
:call_back(call_back), end_call_back(end_call_back)
{
    _search_key = NULL;
    _appendix = NULL;
    _mutex = PTHREAD_MUTEX_INITIALIZER;
    _thread_counter = 0;
}

CLogReader::~CLogReader()
{
    pthread_mutex_destroy(&_mutex);
    Cleanup();
}

bool CLogReader::SetFilter(const char *filter)
{
    if (filter == NULL) { return false; }
    Cleanup();
    _search_key = strdup(filter);
    return _search_key != NULL;
}

bool CLogReader::AddSourceBlock(const char *block, const size_t block_size) {
    if (block == NULL || block_size == 0)
    {
        printf("Warning! invalid arguments");
        return false;
    }

    if (_search_key == NULL) {
        printf("Warning! the search_key has null value");
        return false;
    }

    // making copy of block into BlockInfo
    char *mem = strdup(block);
    if (mem == NULL) { return false; }
    
    BlockInfo *info = (BlockInfo *)malloc(sizeof(BlockInfo));
    info->data = mem;
    info->size = block_size;
    info->reader = this;

    // prepare ThreadInfo structure
    bool result = LaunchThread(info);
    if (!result) {
        info->free();
    }
    return result;
}

void CLogReader::Cleanup() {
    if (_search_key)
    {
        free(_search_key);
        _search_key = NULL;
    }

    if (_appendix) {
        free(_appendix);
        _appendix = NULL;
    }
}

const char * CLogReader::GetFilter() const {
    return _search_key;
}

const char * CLogReader::GetAppendix() const {
    return _appendix;
}

bool CLogReader::SetAppendix(const char *end_line) const {
    if (end_line == NULL)
        return false;

    _appendix = strdup(end_line);
    return _appendix != NULL;
}

void CLogReader::CleanupAppendix() const {
    if (_appendix) {
        free(_appendix);
        _appendix = NULL;
    }
}

bool CLogReader::LaunchThread(BlockInfo *info) {
    pthread_t tid;
    pthread_attr_t  attr;
    
    int error = pthread_attr_init(&attr);
    if (error != 0) {
        printf("\nThread can't be created : [%s]\n", strerror(error));
        return false;
    }
    
    error = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    assert(!error);
    
    error = pthread_attr_setschedpolicy(&attr, SCHED_FIFO);
    assert(!error);

    sched_param param;
    error = pthread_attr_getschedparam(&attr, &param);
    assert(!error);

    param.sched_priority = sched_get_priority_min(SCHED_FIFO);
    error = pthread_attr_setschedparam(&attr, &param);
    assert(!error);
    
    info->thread_counter = ++_thread_counter;
    error = pthread_create(&tid, &attr, &api::FindMatchesInLines, info);
    if (error != 0)
    {
        printf("\nThread can't be created : [%s]\n", strerror(error));
        return false;
    }
    
    int result = pthread_attr_destroy(&attr);
    assert(!result);
    printf("\nCreated thread with number %d\n", _thread_counter);
    return true;
}

void CLogReader::LockThreads() const {
    pthread_mutex_lock(&_mutex);
}

void CLogReader::UnlockThreads() const {
    pthread_mutex_unlock(&_mutex);
}

int CLogReader::NumberOfThreads() const {
    return _thread_counter;
}

void CLogReader::FoundResult(const char *line) const {
    call_back(line);
}
void CLogReader::EndReading() const {
    end_call_back();
}
