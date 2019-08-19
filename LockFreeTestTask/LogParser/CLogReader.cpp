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

#define MAX_PACKAGES 20 //is count of cells for (char*) pointers to string blocks

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
    
    void *FindMatchesInLines(void *arg) {
        BlockInfo * info = (BlockInfo *)arg;
        pthread_mutex_lock(&vars::mutex);
        printf("Started thread number %d\n", info->thread_counter);
        
        // getting appendix_size if it stored from previous block
        // the urlsession loads log file dividing in to parts that ends not '\n'.
        // In this case previous part contains not completed line and next part begins from final part of line.
        char *buffer = NULL;
        if (vars::appendix)
        {
            size_t appendix_size = strlen(vars::appendix);
            buffer = (char *)malloc(appendix_size + info->size + 1); //allocated memory
            memcpy(buffer, vars::appendix, appendix_size);
            memcpy(&buffer[appendix_size], info->data, info->size);
            free(vars::appendix);
            vars::appendix = NULL;
        }

        if (buffer == NULL)
        {
            buffer = (char *)malloc(info->size);
            memcpy(buffer, info->data, info->size);
        }
        // search for lines in the buffer
        char *freed_buffer = buffer;
        char *line_ptr = NULL;
        char *last_line_ptr = NULL;
        while( (line_ptr = strsep(&buffer, "\n")) != NULL )
        {
//            printf("%s\n", line_ptr);
            if (IsLineMatchToKey(line_ptr, info->key)) {
                api::call_back(line_ptr);
            }
            last_line_ptr = line_ptr;
        }

        // store appendix if last line is not completed.
        size_t size_last_line = strlen(last_line_ptr);
        if (last_line_ptr[size_last_line] != '\n' && vars::appendix == NULL)
        {
            vars::appendix = strdup(last_line_ptr);
        }

        //free memory
        int thread_number = info->thread_counter;
        info->free();
        free(freed_buffer);
        
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
    if (filter == NULL) {
        return false;
    }
    void * container = malloc(strlen(filter)+1);
    if (container == NULL)
    {
        return false;
    }
    char * copiedFilter = strcpy((char *)container, filter);
    if (copiedFilter == NULL)
    {
        return false;
    }
    Cleanup();
    vars::search_key = copiedFilter;
    return true;
}

bool CLogReader::AddSourceBlock(const char *block, const size_t block_size) {
    if (block == NULL || block_size == 0)
    {
        printf("Warning! invalid arguments");
        return false;
    }

    if (vars::search_key == NULL) {
        printf("Warning! the search_key has null value.");
        return false;
    }
    // making copy of block into BlockInfo
    char *mem = (char *)malloc(block_size + 1);
    if (mem == NULL)
        return false;
    memcpy(mem, block, block_size);
    
    char *key = NULL;
    size_t key_size = strlen(vars::search_key);
    key = (char *)malloc(key_size + 1);
    if (key == NULL) {
        free(mem);
        return false;
    }
    memcpy(key, vars::search_key, key_size);
    
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
