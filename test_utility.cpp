#include <stdio.h>
#include <stdlib.h>
#include "encoder_main.h"
#include "test_utility.h"

#include "config.h"
#include "dct.h"
#include "bitstream.h"
#include "vlc.h"
#include "slice.h"
#include "encoder.h"
#include "debug.h"


int16_t v_data_result[128*16*2];

int result_block_counter =0;


int v_cr_data_result_flag = 0;

#define Y_DC_RESET_STATE	(1)
#define Y_DC_STATE			(2)
#define Y_AC_RESET_STATE	(3)
#define Y_AC_STATE			(4)
#define END_STATE			(13)
static int vlc_state = 0;

void set_result_dct_data(int16_t *data, Vwrapper *dut) {
	for(int i=0;i<8;i++) {
		for(int j=0;j<8;j++) {
			data[ (i*8) + j] = dut->OUTPUT_DATA[i][j];
		}
	}
}
static int block_counter = 0;

static int vlc_counter = 0;

extern uint8_t block_pattern_scan_read_order_table[64];

void set_pixel_data(Vwrapper *dut, int16_t *data) {
	int i,j;
	for(i=0;i<8;i++) {
		for(j=0;j<8;j++) {
			dut->INPUT_DATA[i][j] = (int32_t)data[((i*8)+j)];
		}
	}

}

void set_qmatrix(Vwrapper *dut, uint8_t *matrix_table){
	int i,j;
	for(i=0;i<8;i++) {
		for(j=0;j<8;j++) {
			dut->QMAT[i][j] = matrix_table[(i*8)+j];
			

		}
	}

}

void set_qscale(Vwrapper *dut, uint8_t qscale) {
	dut->QSCALE = qscale;

}
bool is_run(int time_counter) {
	//printf("is %d\n", time_counter);
	if (time_counter < 10000) {
		return true;

	} else {
		return false;
	}
}

extern void vlc_init(void);

void end_test(Vwrapper *dut) {
//	fclose(out);
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
	dut->CLOCK = !dut->CLOCK; // Toggle clock
}


static int y_first1 = 1;
static int y_first2 = 1;
static int result_first = 1;
static int dc_state_first =1;
static int ac_state_first =1;
static int conefficient = 1;
static int block = 0;
static int position = 0;

void init_test(Vwrapper *dut) {
//	vlc_init();
	block_counter = 0;
	result_block_counter = 0;
	y_first1 = 1;
	y_first2 = 1;
	vlc_state = 0;
	v_cr_data_result_flag=0;
	result_first = 1;
	dc_state_first = 1;
	ac_state_first = 1;
	conefficient = 1;
	block = 0;
	position = 0;

}


#define MAX_BLOCK_NUM	(32)

void posedge_clock_v(int16_t *pixel, Vwrapper *dut, int block_num){
	set_pixel_data(dut, &pixel[(block_counter%MAX_BLOCK_NUM) * 64]);
	block_counter++;

	set_qscale(dut, qscale_table_[0]);
	set_qmatrix(dut, luma_matrix2_);

	if (v_cr_data_result_flag == 1) {

		if (vlc_state == 0) {
			vlc_state = Y_DC_RESET_STATE;
		} else if (vlc_state == Y_DC_RESET_STATE) {
			dut->VLC_RESET = 0;
			vlc_state = Y_DC_STATE;
		} else if (vlc_state == Y_DC_STATE){
			if (dc_state_first) {
				dut->VLC_RESET = 1;
				vlc_counter = 0;
				dc_state_first = 0;
			}

			dut->INPUT_DC_DATA = v_data_result[(vlc_counter*64)%(block_num*64)];

//			if (vlc_counter == 31+12) {
			if (vlc_counter == (block_num-1) + 12) {
				vlc_state = Y_AC_RESET_STATE;
			}
		} else if (vlc_state == Y_AC_RESET_STATE) {
			dut->VLC_RESET = 0;
			vlc_state = Y_AC_STATE;
		} else if (vlc_state == Y_AC_STATE){

			if (ac_state_first) {
				dut->VLC_RESET = 1;
				vlc_counter = 0;
				ac_state_first = 0;
			}
			if (block == 0) {
	        	position = block_pattern_scan_read_order_table[conefficient%64];
			}

			if (conefficient < 64) {
				dut->INPUT_AC_DATA = v_data_result[(block * 64) + position];
			}  else {
				dut->INPUT_AC_DATA = 1;
			}
			//printf("conefficient %d\n", conefficient);

			block++;
			if (block == block_num) {
				block = 0;
				conefficient++;
			}

			if (conefficient == 65) {
				vlc_state = END_STATE;
			}
		}
		vlc_counter++;
	}
//	printf("state=%d\n", vlc_state);

}

void posedge_clock_result_v(Vwrapper *dut, struct bitstream *bitstream, int block_num) {
		result_first++;
		if (result_first>=12) {
			if (result_block_counter>=0 && result_block_counter<block_num) {
				set_result_dct_data(&v_data_result[(result_block_counter*64)], dut);
				result_block_counter++;
				if (result_block_counter == (block_num-1)) {
					v_cr_data_result_flag = 1;
				}

			}
		}

	if (dut->VLC_RESET) {
		if (vlc_state == Y_DC_STATE){
			static int counter = 0;

			if (vlc_state == Y_DC_STATE) {
				if (y_first1) {
					y_first1 = 0;
					counter = 0;
				}
			}

			if ((counter> 2) && (counter<(block_num+3))) {
				setBit(bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
			}
			counter++;

		} else if (vlc_state == Y_AC_STATE){
			static int counter = 0;
			if (y_first2) {
				counter = 0;
				y_first2 = 0;
			}

			static uint32_t run_length=0;
			static uint32_t run_sum=0;
			static uint32_t run_length_n=0;
			static uint32_t run_sum_n=0;
			if (counter < ((block_num * 63) +2)) {
				//printf("level %d %x\n", dut->AC_BITSTREAM_LEVEL_OUTPUT_ENABLE, dut->AC_BITSTREAM_LEVEL_SUM);
				if (dut->AC_BITSTREAM_LEVEL_LENGTH) {
					//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
					run_length_n = run_length;
					run_sum_n = run_sum;
						//printf("%d %x\n", run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

					setBit(bitstream, run_sum_n, run_length_n);
					setBit(bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
				}
				if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
					run_length = dut->AC_BITSTREAM_RUN_LENGTH;
					run_sum = dut->AC_BITSTREAM_RUN_SUM;
				}
				//	printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
			}

			counter++;

		}
	} else {
//		printf("VLC_RESET %d\n", dut->VLC_RESET);
	}

}
