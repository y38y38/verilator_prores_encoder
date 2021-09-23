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

void set_pixel_data_mem(Vwrapper *dut, int16_t *y_pixel,int16_t *cb_pxiel,int16_t *cr_pixel );
void set_qmatrix(Vwrapper *dut, uint8_t *y_matrix_table, uint8_t *c_matrix_table);
void set_qscale(Vwrapper *dut, uint8_t qscale);

extern uint32_t horizontal_;
extern uint32_t vertical_;


int y_size = 0;
int cb_size = 0;

//static int time_counter = 0;
uint32_t encode_slice_component_v(int16_t* y_pixel, 
									int16_t* cb_pixel,
									int16_t* cr_pixel,
									uint8_t *y_matrix, 
									uint8_t *c_matrix,
									uint8_t qscale, 
									int block_num, 
									struct bitstream *bitstream) {
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



	dut->header_horizontal = horizontal_;
	dut->header_vertical = vertical_;
	dut->header_chroma_format = 2;
	dut->header_interlace_mode = 0;
	dut->header_aspect_ratio_information = 0;
	dut->header_frame_rate_code = 0;
	dut->header_color_primaries = 0;
	dut->header_transfer_characteristic = 0;
	dut->header_matrix_coefficients = 2;
	dut->header_alpha_channel_type = 0;


	set_pixel_data_mem(dut, y_pixel, cb_pixel, cr_pixel);
	set_qscale(dut, qscale_table_[0]);
	set_qmatrix(dut, y_matrix, c_matrix);
	dut->block_num = block_num;

	while (is_run(time_counter) && !Verilated::gotFinish()) {
		toggle_clock(dut);
		if (!dut->CLOCK) {
			posedge_clock_input(time_counter, dut, y_pixel, block_num);
		}
		dut->eval();
		if (!dut->CLOCK) {
			posedge_clock_output(time_counter, dut, bitstream, block_num);
			time_counter++;
		}
	}
	end_test(dut);
	dut->final();
	y_size = dut->slice_sequencer_y_size;
	cb_size = dut->slice_sequencer_cb_size;

	return 0;
}

