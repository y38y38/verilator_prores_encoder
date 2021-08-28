#include <stdio.h>
#include <stdlib.h>
#include "encoder_main.h"
#include "test_utility.h"
#include "encode_component.h"


#include "config.h"
#include "dct.h"
#include "bitstream.h"
#include "vlc.h"
#include "slice.h"
#include "encoder.h"
#include "debug.h"

#if 1
static int time_counter = 0;
uint32_t encode_slice_component_v(int16_t* pixel, uint8_t *matrix, uint8_t qscale, int block_num, struct bitstream *bitstream) {
	
	// Instantiate DUT
	Vwrapper *dut = new Vwrapper();
	time_counter = 0;
	// Format
	init_test(dut);

	reset_test(dut);

	// Reset Time
	while (time_counter < 10) {
		toggle_clock(dut);
		time_counter++;
	}
	// Release reset
	unreset_test(dut);
	while (is_run(time_counter) && !Verilated::gotFinish()) {
		toggle_clock(dut);
		if (dut->CLOCK) {
			posedge_clock_v(pixel, dut,block_num);
		}
		dut->eval();
		if (dut->CLOCK) {
			posedge_clock_result_v(dut, bitstream, block_num);
		}
		time_counter++;
	}
	end_test(dut);
	dut->final();
	return 0;
}

#endif