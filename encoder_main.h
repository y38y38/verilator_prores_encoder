#ifndef __ENCODER_MAIN__
#define __ENCODER_MAIN__
#include <stdint.h>

#include "prores.h" 
#include "encoder.h"

int32_t GetParam(int argc, char **argv);


extern uint8_t luma_matrix2_[MATRIX_NUM];
extern uint8_t chroma_matrix2_[MATRIX_NUM];


extern uint8_t  qscale_table_[MAX_SLICE_NUM];


#endif

