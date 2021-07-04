#ifndef __TEST_UTILITY_H__
#define __TEST_UTILITY_H__
#include <verilated.h>
#include <verilated_fst_c.h> 
#include "Vwrapper.h"


int init_param(int argc, char** argv);

void init_test(Vwrapper *dut);
void end_test(Vwrapper *dut);

void reset_test(Vwrapper *dut);
void unreset_test(Vwrapper *dut);

void toggle_clock(Vwrapper *dut);

void posedge_clock(Vwrapper *dut);
void posedge_clock_result(Vwrapper *dut);

#endif
