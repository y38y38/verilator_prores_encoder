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


extern uint8_t block_pattern_scan_read_order_table[64];


#define MAX_BLOCK_NUM	(32)
#define MAX_PIXEL_NUM	(64)
#define BYTE_PER_PIXEL	(2)


#define Y_DC_RESET_STATE	(1)
#define Y_DC_STATE			(2)
#define Y_AC_RESET_STATE	(3)
#define Y_AC_STATE			(4)
#define END_STATE			(13)
static int vlc_state = 0;


int16_t v_data_result[128*16];


void set_result_dct_data(int16_t *data, Vwrapper *dut) {
	for(int i=0;i<8;i++) {
		for(int j=0;j<8;j++) {
			data[ (i*8) + j] = dut->OUTPUT_DATA[i][j];
		}
	}
}


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
	if (time_counter < (10000/2)) {
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
	dut->CLOCK = !dut->CLOCK; // Toggle clock
}


static int dc_vlc_counter = 0;
static int ac_vlc_counter = 0;
void init_test(Vwrapper *dut) {
	vlc_state = 0;
	dc_vlc_counter = 0;
	ac_vlc_counter = 0;


}


void posedge_clock_input(int time_counter, Vwrapper *dut, int16_t *pixel, int block_num){
	
	set_pixel_data(dut, &pixel[(time_counter%MAX_BLOCK_NUM) * MAX_PIXEL_NUM]);

	set_qscale(dut, qscale_table_[0]);
	set_qmatrix(dut, luma_matrix2_);

	//until dct output 
	if (time_counter == block_num + 11) {
		dut->VLC_RESET = 0;
	} else if ((time_counter >= block_num + 12) 
				&& (time_counter < (block_num + 56)) //今は、出力する時間も含めて56としている
				) {
		if (time_counter == block_num + 12) {
			dut->VLC_RESET = 1;
			vlc_state = Y_DC_STATE;
		}
		int counter = ((time_counter - (block_num + 12))*64);
		dut->INPUT_DC_DATA = v_data_result[counter %(block_num*MAX_PIXEL_NUM)];
		//printf("%d %d\n", time_counter, dut->INPUT_DC_DATA);
	} else if (time_counter == block_num + 56) {
		//printf("b %d\n", block_num);
		dut->VLC_RESET = 0;
	} else if ((time_counter >= block_num + 57) 
				&& (time_counter < (63 * block_num) + 57 + block_num + 3 )
			) {
	    if (time_counter == block_num + 57)  {
			dut->VLC_RESET = 1;
			vlc_state = Y_AC_STATE;
		}
		int conefficient1 = ((time_counter - (block_num + 57)) /  block_num) + 1; 
    	int position = block_pattern_scan_read_order_table[conefficient1%MAX_PIXEL_NUM];
		int block = (time_counter - (block_num + 57)) % block_num;
		if (conefficient1 < MAX_PIXEL_NUM) {
			dut->INPUT_AC_DATA = v_data_result[(block * MAX_PIXEL_NUM) + position];
		}  else {
			dut->INPUT_AC_DATA = 1;
		}
	} else {
		dut->VLC_RESET = 0;
	}

}

void posedge_clock_output(int time_counter, Vwrapper *dut, struct bitstream *bitstream, int block_num) {

	if (time_counter>=10) {
		if (time_counter>=10 && ((time_counter - 10) < block_num)) {
			set_result_dct_data(&v_data_result[(((time_counter - 10) % MAX_BLOCK_NUM ) * 64)], dut);
		}
	}

	if (dut->VLC_RESET) {
		if (vlc_state == Y_DC_STATE){

			if ((dc_vlc_counter> 3) && (dc_vlc_counter<(block_num+4))) {
				setBit(bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
				//printf("%x %d\n", dut->DC_BITSTREAM_SUM, dut->LENGTH);
			}
			dc_vlc_counter++;

		} else if (vlc_state == Y_AC_STATE){

			static uint32_t run_length=0;
			static uint32_t run_sum=0;
			if (ac_vlc_counter < ((block_num * 63) +2)) {
				if (dut->AC_BITSTREAM_LEVEL_LENGTH) {

					setBit(bitstream, run_sum, run_length);
					setBit(bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
				}
				if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
					run_length = dut->AC_BITSTREAM_RUN_LENGTH;
					run_sum = dut->AC_BITSTREAM_RUN_SUM;
				}
				//	printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
			}

			ac_vlc_counter++;

		}
	} else {
//		printf("VLC_RESET %d\n", dut->VLC_RESET);
	}

}
