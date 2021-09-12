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

void set_pixel_data_mem(Vwrapper *dut, int16_t *data);

//static int time_counter = 0;
uint32_t encode_slice_component_v(int16_t* pixel, uint8_t *matrix, uint8_t qscale, int block_num, struct bitstream *bitstream) {
	int time_counter;	
	// Instantiate DUT
	Vwrapper *dut = new Vwrapper();
	// Format
	init_test(dut);

	reset_test(dut);

	// Reset Time
	time_counter = 0;
	while (time_counter < 10) {
		toggle_clock(dut);
		dut->eval();
		if (dut->CLOCK) {
			time_counter++;
		}
	}
	// Release reset
	unreset_test(dut);
	dut->CLOCK = 1;
	time_counter = 0;
//printf("s\n");

	set_pixel_data_mem(dut, pixel);
	dut->block_num = block_num;

	while (is_run(time_counter) && !Verilated::gotFinish()) {
		toggle_clock(dut);
		if (!dut->CLOCK) {
			posedge_clock_input(time_counter, dut, pixel, block_num);
		}
		dut->eval();
		if (!dut->CLOCK) {
			posedge_clock_output(time_counter, dut, bitstream, block_num);
			time_counter++;
		}
	}
	end_test(dut);
	dut->final();
	return 0;
}

