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

using namespace std;

class CLogReader final {
public:
    CLogReader( function<void(const char *)> call_back, function<void(void)> end_call_back );
    ~CLogReader();
    /**
     */
    // установка фильтра строк, false - ошибка
    bool SetFilter(const char *filter);
    // добавление очередного блока текстового файла
    bool AddSourceBlock(const char *block, const size_t block_size);
    
private:
    void Cleanup();
};
#endif /* CLogReader_hpp */
