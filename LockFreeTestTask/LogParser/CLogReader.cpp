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

namespace vars {
    char *appendix = NULL;
    char *search_key = NULL;
    char **blocks = NULL;
    unsigned int block_index = 0;
    unsigned int current_index = 0;
    unsigned int multiplyer = 1;
    
    pthread_mutex_t mutex;

    int thread_counter = 0;
}

typedef struct BlockInfo {
    const char * data;
    const char * key;
    size_t size;
    int thread_counter = 0;
    void free() {
        ::free((void *)key);
        ::free((void *)data);
        ::free(this);
    }
} BlockInfo;

namespace api {

    function<void(const char *)> call_back;
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
    
    void SaveAppendix(const char* appendix) {
        if (!appendix) return;
        size_t size_last_line = strlen(appendix);
        if ( size_last_line && vars::appendix == NULL )
            vars::appendix = strdup(appendix);
    }

    void *FindMatchesInLines(void *arg) {
        BlockInfo * info = (BlockInfo *)arg;
        pthread_mutex_lock(&vars::mutex);
        printf("Started thread number %d\n", info->thread_counter);
        
        // getting appendix_size if it stored from previous block
        // the urlsession loads log file by short parts. Every part might finish not by '\n'.
        // In this case previous part contains not completed line and next part begins from final previous part of line.
        char *buffer = NULL;
        if (vars::appendix)
        {/// I really don't understand why but works for me based on memory api: memcpy, malloc
         /// I tryed strcat - smth going with memory
            size_t appendix_size = strlen(vars::appendix);
            size_t size = appendix_size + info->size;
            buffer = (char*)malloc(size +1);
            memcpy(buffer, vars::appendix, appendix_size);
            memcpy(buffer + appendix_size, info->data, info->size);
            buffer[size] = '\0';
            free(vars::appendix);
            vars::appendix = NULL;
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
                if (IsLineMatchToKey(copied_line, info->key)){
                    api::call_back(copied_line);
                }
                //
                line_ptr = block;
                free(copied_line);
            }
        }

        // store appendix if last line is not completed end line sign \n.
        SaveAppendix(line_ptr);
        if (buffer != NULL)
            free(buffer);

        //free memory
        int thread_number = info->thread_counter;
        info->free();
        
        pthread_mutex_unlock(&vars::mutex);
        printf("Finished thread number %d\n", thread_number);
        return NULL;
    }

    bool LaunchThread(BlockInfo *info) {
        pthread_t tid;
        pthread_attr_t  attr;
        
        int error = pthread_attr_init(&attr);
        if (error != 0) {
            printf("\nThread can't be created : [%s]\n", strerror(error));
            return false;
        }
        
        error = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        assert(!error);
        
        sched_param param;
        error = pthread_attr_getschedparam(&attr, &param);
        assert(!error);

        param.sched_priority = sched_get_priority_min(SCHED_FIFO);
        error = pthread_attr_setschedparam(&attr, &param);
        assert(!error);
        
        info->thread_counter = ++vars::thread_counter;
        error = pthread_create(&tid, &attr, &FindMatchesInLines, info);
        if (error != 0)
        {
            printf("\nThread can't be created : [%s]\n", strerror(error));
            return false;
        }
        
        int result = pthread_attr_destroy(&attr);
        assert(!result);
        printf("\nCreated thread with number %d\n", vars::thread_counter);
        return true;
    }
}

CLogReader::CLogReader(function<void(const char *)> call_back)
{
    vars::search_key = NULL;
    vars::appendix = NULL;
    vars::mutex = PTHREAD_MUTEX_INITIALIZER;
    api::call_back = call_back;
}

CLogReader::~CLogReader()
{
    pthread_mutex_destroy(&vars::mutex);
    Cleanup();
    free(vars::blocks);
}

bool CLogReader::SetFilter(const char *filter)
{
    if (filter == NULL) { return false; }
    Cleanup();
    vars::search_key = strdup(filter);
    if (vars::search_key == NULL) { return false; }
    return true;
}

bool CLogReader::AddSourceBlock(const char *block, const size_t block_size) {
    if (block == NULL || block_size == 0)
    {
        printf("Warning! invalid arguments");
        return false;
    }

    if (vars::search_key == NULL) {
        printf("Warning! the search_key has null value");
        return false;
    }

    // making copy of block into BlockInfo
    char *mem = strdup(block);
    if (mem == NULL) { return false; }
    
    char *key = strdup(vars::search_key);
    if (!key) {
        free(mem);
        return false;
    }
    
    BlockInfo *info = (BlockInfo *)malloc(sizeof(BlockInfo));
    info->data = mem;
    info->key = key;
    info->size = block_size;

    // prepare ThreadInfo structure
    bool result = api::LaunchThread(info);
    if (!result) {
        info->free();
    }
    return result;
}

void CLogReader::Cleanup() {
    if (vars::search_key)
    {
        free(vars::search_key);
        vars::search_key = NULL;
    }
}
