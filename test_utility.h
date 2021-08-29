#ifndef __TEST_UTILITY_H__
#define __TEST_UTILITY_H__
#include <verilated.h>
//#include <verilated_fst_c.h> 
#include "Vwrapper.h"

#include "config.h"
#include "dct.h"
#include "bitstream.h"
#include "vlc.h"
#include "slice.h"

int init_param(int argc, char** argv);


bool is_run(int time_counter);

void init_test(Vwrapper *dut);
void end_test(Vwrapper *dut);

void reset_test(Vwrapper *dut);
void unreset_test(Vwrapper *dut);

void toggle_clock(Vwrapper *dut);

void posedge_clock(Vwrapper *dut);
void posedge_clock_result(Vwrapper *dut);


void posedge_clock_input(int time_counter, Vwrapper *dut, int16_t *pixel, int block_num);
void posedge_clock_output(int time_counter, Vwrapper *dut, struct bitstream * bitstream, int block_num);



#endif
