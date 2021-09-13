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
	//printf("data %d %d\n", data[0], dut->OUTPUT_DATA[0][0]);
}

void set_pixel_data_mem(Vwrapper *dut, int16_t *data) {
	for(int i=0;i<2048;i++) {
//	for(int i=0;i<64;i++) {
		dut->INPUT_DATA_MEM[i] = (int32_t)data[i];
	}
}

void set_pixel_data(Vwrapper *dut, int16_t *data) {
#if 1
	for(int i=0;i<64;i++) {
//		dut->INPUT_DATA_MEM[i] = (int32_t)data[i];
		dut->INPUT_DATA[i] = (int32_t)data[i];
	}

#else
	for(int i=0;i<8;i++) {
		for(int j=0;j<8;j++) {
			dut->INPUT_DATA_ARRAY[i][j] = (int32_t)data[((i*8)+j)];
		}
	}
#endif
	#if 0
	for (int i=0;i<64;i++) {
		printf("%x ", data[i]);
		if((i%8) == 7) {
			printf("\n");
		}
	}
	printf("\n");
	for(int i=0;i<8;i++) {
		for(int j=0;j<8;j++) {
			printf("%x %x %x\n", dut->INPUT_DATA[i][j], i, j);
		}
	}
	printf("\n");
#endif
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
	//printf("t %d %d\n", dut->sequence_counter,dut->CLOCK);
	dut->CLOCK = !dut->CLOCK; // Toggle clock
}


static int dc_vlc_counter = 0;
static int ac_vlc_counter = 0;
void init_test(Vwrapper *dut) {
	vlc_state = 0;
	dc_vlc_counter = 0;
	ac_vlc_counter = 0;


}

#define DCT_TIME	(11)

void posedge_clock_input(int time_counter, Vwrapper *dut, int16_t *pixel, int block_num){


	dut->set_bit_enable = 0;
	dut->set_bit_val = 0;
	dut->set_bit_size_of_bit = 0;
	dut->set_bit_flush_bit = 0;

//	if(!dut->vlc_reset3) {
		//printf("pin %d %d\n", dut->vlc_reset3, dut->sequence_counter);

//	}
	//until dct output 

	if (time_counter == block_num + DCT_TIME+2) {
//		dut->VLC_RESET = 0;
		//printf("dc reset %d %d %d\n", dut->sequence_counter, dut->sequence_counter - block_num, dut->vlc_reset2);
//		printf("pin %d\n", dut->vlc_reset2);
	} else if ((time_counter >= block_num + DCT_TIME+3) 
				&& (time_counter < (block_num + DCT_TIME+47)) //今は、出力する時間も含めて56としている
				) {
		if (time_counter == block_num + DCT_TIME+3) {
//			dut->VLC_RESET = 1;
			vlc_state = Y_DC_STATE;
		//printf("dc reset rel %d %d %d\n", dut->sequence_counter,dut->sequence_counter - block_num, dut->vlc_reset2);
//		printf(" pin %d\n", dut->vlc_reset2);
		}
		int counter = ((time_counter - (block_num + DCT_TIME+2))*64);
//		dut->INPUT_DC_DATA = v_data_result[counter %(block_num*MAX_PIXEL_NUM)];
//		dut->INPUT_DC_DATA = dut->v_data_result[counter %(block_num*MAX_PIXEL_NUM)];
		//printf("%d %d\n", time_counter, dut->INPUT_DC_DATA);
		//printf("%d %d %d %d \n", counter ,dut->dc_vlc_counter * 64, time_counter ,dut->INPUT_DC_DATA2);
		
		//printf("dc %x %d %d\n", dut->INPUT_DC_DATA2,dut->INPUT_DC_DATA2, dut->dc_vlc_reset);
		if ((dc_vlc_counter> 5) && (dc_vlc_counter<(block_num+6))) {
			dut->set_bit_enable = 1;
			dut->set_bit_val = dut->DC_BITSTREAM_SUM;
			dut->set_bit_size_of_bit = dut->LENGTH;
			dut->set_bit_flush_bit = 0;
			//printf("a %x %d\n", dut->DC_BITSTREAM_SUM, dut->LENGTH);
		}
		dc_vlc_counter++;

	} else if (time_counter == block_num + DCT_TIME+46) {
//		dut->VLC_RESET = 0;
		//printf("ac reset %d %d %d\n", dut->sequence_counter,dut->sequence_counter - block_num, dut->vlc_reset3);
	} else if ((time_counter >= block_num + DCT_TIME+47) 
				&& (time_counter < (63 * block_num) + DCT_TIME+47 + block_num  +5 )
			) {
	    if (time_counter == block_num + DCT_TIME+47)  {
//			dut->VLC_RESET = 1;
			vlc_state = Y_AC_STATE;
		//printf("ac reset rel %d %d %d\n", dut->sequence_counter,dut->sequence_counter - block_num,dut->vlc_reset3);
		}
		int conefficient1 = ((time_counter - (block_num + DCT_TIME+47)) /  block_num) + 1; 
    	int position = block_pattern_scan_read_order_table[conefficient1%MAX_PIXEL_NUM];
		int block = (time_counter - (block_num + DCT_TIME+47)) % block_num;
		if (conefficient1 < MAX_PIXEL_NUM) {

//			dut->INPUT_AC_DATA = v_data_result[(block * MAX_PIXEL_NUM) + position];
			dut->INPUT_AC_DATA = dut->v_data_result[(block * MAX_PIXEL_NUM) + position];
	    if (time_counter == block_num + DCT_TIME+47)  {
		//	printf("v %d %d %d\n", dut->INPUT_AC_DATA, block,position);
		}
//			printf("v %d\n", dut->INPUT_AC_DATA);
		}  else {
			//dut->INPUT_AC_DATA = 1;
		//printf("e\n");
		}
		//printf("%d %d\n", ac_vlc_counter, dut->INPUT_AC_DATA);
		if (ac_vlc_counter < ((block_num * 63) +100)) {
			if (dut->AC_BITSTREAM_LEVEL_LENGTH) {

				uint64_t data = (dut->AC_BITSTREAM_RUN_SUM << dut->AC_BITSTREAM_LEVEL_LENGTH)|dut->AC_BITSTREAM_LEVEL_SUM;
				uint64_t length = dut->AC_BITSTREAM_LEVEL_LENGTH + dut->AC_BITSTREAM_RUN_LENGTH;
			//	printf("a c %d %llx %d %llx %llx %d %d %d\n", dut->set_bit_enable, data, length, dut->AC_BITSTREAM_RUN_SUM, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_RUN_LENGTH, dut->AC_BITSTREAM_LEVEL_LENGTH, ac_vlc_counter);

				dut->set_bit_enable = 1;
				dut->set_bit_val = data;
				dut->set_bit_size_of_bit = length;
				dut->set_bit_flush_bit = 0;
				//printf("b %x %d\n", data, length);
			}
		}

			ac_vlc_counter++;


	} else if  (time_counter == (63 * block_num) + DCT_TIME+47 + block_num +5  ) {
		dut->VLC_RESET = 0;
		dut->set_bit_flush_bit = 1;
		dut->set_bit_enable = 0;
		dut->set_bit_val = 0;
		dut->set_bit_size_of_bit = 0;
		//printf("flush\n");
	} else {
//		dut->VLC_RESET = 0;
//		printf("e\n");
	}
	if ((time_counter >= block_num + DCT_TIME+48 -2) 
				&& (time_counter < (63 * block_num) + DCT_TIME+48 + block_num  +5 )) {
	//printf("t %d %d %llx %llx %d %d\n", time_counter, ac_vlc_counter,	dut->AC_BITSTREAM_RUN_SUM,dut->AC_BITSTREAM_LEVEL_SUM, dut->ac_vlc_reset, dut->INPUT_AC_DATA);
	}

}

void posedge_clock_output(int time_counter, Vwrapper *dut, struct bitstream *bitstream, int block_num) {
#if 0
	if (time_counter>=11) {
		if (time_counter>=11 && ((time_counter - 11) < block_num)) {
			if(time_counter == 11) {
				//printf("%d \n", dut->DCT_OUTPUT[0][0]);
			}
			set_result_dct_data(&v_data_result[(((time_counter - 11) % MAX_BLOCK_NUM ) * 64)], dut);
		}
	}
#else
//	if ((time_counter>=0) && (time_counter <= 5)) {
	if ((time_counter>=0) && (time_counter <= 5)) {
		//printf("b0 %d %d %d\n",dut->INPUT_DATA_MEM[0],dut->INPUT_DATA_MEM[1], dut->sequence_counter);
		//printf("b1 %d %d\n",dut->OUTPUT_DATA[0][0],dut->OUTPUT_DATA[0][1]);
		//printf("b1 %d %d %d %d\n",dut->INPUT_DATA_ARRAY[0][0],dut->INPUT_DATA_ARRAY[0][1], dut->sequence_counter,dut->INPUT_DATA[0]);
		//printf("b2 %d %d %d %d\n",dut->INPUT_DATA_ARRAY2[0][0],dut->INPUT_DATA_ARRAY2[0][1], dut->sequence_counter,dut->INPUT_DATA_MEM[0]);
	}
	if((time_counter >= DCT_TIME-1) && (time_counter <= DCT_TIME+4)) {
//		printf("%d %d %d %d %d %d %d\n"
		
//		, dut->DCT_OUTPUT[0][0], dut->OUTPUT_DATA[0][0],time_counter,v_data_result[0],time_counter,dut->QSCALE, dut->QMAT[0][0]);
//		, dut->PRE_DCT_OUTPUT[0][0], dut->DCT_OUTPUT[0][0],time_counter,v_data_result[0],time_counter,dut->QSCALE, dut->QMAT[0][0]);
	}
	if (time_counter>=DCT_TIME) {
		if (time_counter>=DCT_TIME && ((time_counter - DCT_TIME) < block_num)) {
			//set_result_dct_data(&v_data_result[(((time_counter - DCT_TIME) % MAX_BLOCK_NUM ) * 64)], dut);
			//printf("%d %d\n", dut->sequence_counter2, (((time_counter - DCT_TIME) % MAX_BLOCK_NUM )));
		}
	}
#endif

	if (dut->VLC_RESET) {
		if (vlc_state == Y_DC_STATE){

		} else if (vlc_state == Y_AC_STATE){
			
		}
	} else {
//		printf("VLC_RESET %d\n", dut->VLC_RESET);
	}

	//printf("sequence_counter %d\n",dut->sequence_counter);
	uint64_t data = dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8));
	uint64_t length = dut->set_bit_output_enable_byte*8;
	if (dut->set_bit_output_enable_byte) {
		if (length > 23) {
			//printf("v %llx %llx\n", data, length);
			setBit(bitstream, dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8))>>23, (dut->set_bit_output_enable_byte*8) - 23);
			//printf("v1 %llx %llx\n", dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8))>>23, (dut->set_bit_output_enable_byte*8) - 23);
			setBit(bitstream, dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8))&0x7fffff, 23);
			//printf("v2 %llx %llx\n", dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8))&0x7fffff, 23);
		} else {
			setBit(bitstream, dut->set_bit_output_val >> (64 - (dut->set_bit_output_enable_byte*8)), dut->set_bit_output_enable_byte*8);
		}
		//printf("vb %d %llx %llx %d\n", dut->set_bit_enable, dut->set_bit_val, dut->set_bit_size_of_bit, dut->set_bit_flush_bit);
		//	printf("v %llx %d %d %x %d  %llx %llx\n", 0, 0, dut->set_bit_flush_bit,dut->set_bit_tmp_bit, dut->set_bit_tmp_buf_bit_offset
		//	,dut->set_bit_output_enable_byte, dut->set_bit_output_val);
	}
}
