#include <stdio.h>
#include <stdlib.h>

#include "config.h"
#include "dct.h"
#include "bitstream.h"
#include "vlc.h"
#include "slice.h"
#include "encoder.h"
#include "debug.h"

#include "encoder_main.h"

#include "test_utility.h"


void set_pixel_data_mem(Vwrapper *dut, int16_t *y_pixel, int16_t *cb_pixel, int16_t *cr_pixel) {
	for(int i=0;i<2048;i++) {
		dut->INPUT_DATA_MEM[i] = (int32_t)y_pixel[i];
	}
	for(int i=0;i<1024;i++) {
		dut->INPUT_DATA_MEM[2048+i] = (int32_t)cb_pixel[i];
	}
	for(int i=0;i<1024;i++) {
		dut->INPUT_DATA_MEM[2048+1024+i] = (int32_t)cr_pixel[i];
	}

}
void set_qmatrix(Vwrapper *dut, uint8_t *y_matrix_table,uint8_t *c_matrix_table){
	int i,j;
	for(i=0;i<8;i++) {
		for(j=0;j<8;j++) {
			dut->Y_QMAT[i][j] = y_matrix_table[(i*8)+j];
			

		}
	}
	for(i=0;i<8;i++) {
		for(j=0;j<8;j++) {
			dut->C_QMAT[i][j] = c_matrix_table[(i*8)+j];
			

		}
	}

}

void set_qscale(Vwrapper *dut, uint8_t qscale) {
	dut->QSCALE = qscale;

}
bool is_run(int time_counter) {
	//printf("is %d\n", time_counter);
	if (time_counter < (40000)) {
		return true;

	} else {
		return false;
	}
}


void end_test(Vwrapper *dut) {
}

void reset_test(Vwrapper *dut) {
	dut->RESET = 0;
	dut->CLOCK = 0;
}
void unreset_test(Vwrapper *dut) {
	dut->RESET = 1;
}

int init_param(int argc, char** argv) {
	return 0;
}


void toggle_clock(Vwrapper *dut) {
	//printf("t %d %d\n", dut->sequence_counter,dut->CLOCK);
	dut->CLOCK = !dut->CLOCK; // Toggle clock
}


void init_test(Vwrapper *dut) {

}

#define DCT_TIME	(11)

void posedge_clock_input(int time_counter, Vwrapper *dut, int16_t *pixel, int block_num){


}

void posedge_clock_output(int time_counter, Vwrapper *dut, struct bitstream *bitstream, int block_num) {
	uint64_t data = dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8));
	uint64_t length = dut->set_bit_output_enable_byte*8;
	if (dut->set_bit_output_enable_byte) {
		if (length > 23) {
//			printf("v %llx %llx\n", data, length);
			setBit(bitstream, dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8))>>23, (dut->set_bit_output_enable_byte*8) - 23);
			//printf("v1 %llx %llx\n", dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8))>>23, (dut->set_bit_output_enable_byte*8) - 23);
			setBit(bitstream, dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8))&0x7fffff, 23);
			//printf("v2 %llx %llx\n", dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8))&0x7fffff, 23);
		} else {
			setBit(bitstream, dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8)), dut->set_bit_output_enable_byte*8);
		}
	}
	if (dut->slice_sequencer_byte_size) {
		uint8_t tmp[4];
		if(dut->slice_sequencer_byte_size == 2) {
			tmp[1] = (uint8_t)(dut->slice_sequencer_val&0xff);
			tmp[0] = (uint8_t)((dut->slice_sequencer_val&0xff00) >> 8);

		} else if(dut->slice_sequencer_byte_size == 4) {
			tmp[3] = (uint8_t)(dut->slice_sequencer_val&0xff);
			tmp[2] = (uint8_t)((dut->slice_sequencer_val&0xff00) >> 8);
			tmp[1] = (uint8_t)((dut->slice_sequencer_val&0xff0000)>>16);
			tmp[0] = (uint8_t)((dut->slice_sequencer_val&0xff000000) >> 24);
		} else {
			printf("err?");
		}
//		printf("w %d %d %d\n", dut->slice_sequencer_offset_addr,
//							dut->slice_sequencer_val,
//							dut->slice_sequencer_byte_size);
		setByteInOffset(bitstream, 
				dut->slice_sequencer_offset_addr,
				tmp,
				dut->slice_sequencer_byte_size);
	}

}
