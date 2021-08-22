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

#define MAX_X   (8)
#define MAX_Y   (8)
int org[MAX_X * MAX_Y];

FILE *in = NULL;
FILE *out = NULL;
int width = 0;
int height = 0;


extern int16_t v_y_data[128*16*2];
extern int16_t v_cb_data[128*16];
extern int16_t v_cr_data[128*16];

int16_t v_y_data_result[128*16*2];
int16_t v_cb_data_result[128*16];
int16_t v_cr_data_result[128*16];

int result_block_counter =0;

int result_y_block_counter =0;
int result_cb_block_counter =0;
int result_cr_block_counter =0;


int v_y_data_result_flag = 0;
int v_cb_data_result_flag = 0;
int v_cr_data_result_flag = 0;

	#define Y_DC_RESET_STATE	(1)
	#define Y_DC_STATE			(2)
	#define Y_AC_RESET_STATE	(3)
	#define Y_AC_STATE			(4)
	#define	CB_DC_RESET_STATE	(5)
	#define	CB_DC_STATE			(6)
	#define CB_AC_RESET_STATE	(7)
	#define CB_AC_STATE			(8)
	#define CR_DC_RESET_STATE	(9)
	#define CR_DC_STATE			(10)
	#define CR_AC_RESET_STATE	(11)
	#define CR_AC_STATE			(12)
	#define END_STATE			(13)
	static int vlc_state = 0;


extern struct Slice slice_param[MAX_SLICE_NUM];
extern uint32_t code_size_of_y_data_offset;
extern uint32_t code_size_of_cb_data_offset;
extern uint32_t slice_start_offset;
extern struct bitstream write_bitstream;
void write_slice_size(int slice_no, int size);
void setSliceTalbeFlush(uint16_t size, uint32_t offset);
extern     uint32_t slice_size_table_offset;


extern uint32_t picture_size_offset_;
extern uint32_t frame_size_offset;
extern uint32_t picture_size_offset;
extern uint16_t slice_size_table[MAX_SLICE_NUM];
extern FILE *slice_output;


void posedge_clock_result(Vwrapper *dut){
//	printf("aa");
//return ;
		static int first = 1;
		//		printf("\n");
//		if ((first<15)&&(first>10)) {
		if (first==2) {
			int i,j;
//			printf("%d\n", first);
			for(i=0;i<8;i++) {
				for(j=0;j<8;j++) {
//					fprintf(out, "%d\n", dut->OUTPUT_DATA[i][j]);
					//printf("%d ", dut->PRE_DCT_OUTPUT[i][j]);
//					printf("%d ", dut->DCT_OUTPUT[i][j]);

				}
			}
				//printf("\n");
//				printf("\n");
			for(i=0;i<8;i++) {
				for(j=0;j<8;j++) {
//					fprintf(out, "%d\n", dut->OUTPUT_DATA[i][j]);
//					printf("%d ", dut->PRE_DCT_OUTPUT[i][j]);
//					printf("%d ", dut->DCT_OUTPUT[i][j]);
//					printf("%.08x ", dut->OUTPUT_DATA[i][j]);
//					printf("%d ", dut->OUTPUT_DATA[i][j]);

				}
//				printf("\n");
			}
		}
		first++;
		if (first>=12) {
//		if (1) {
//			printf("e %d %d\n", first,result_block_counter );
			if (result_block_counter>=0 && result_block_counter<32) {
//			printf("s %d %d\n", first,result_block_counter );
//				memcpy(&v_y_data_result[result_y_block_counter*64], dut->DCT_OUTPUT, 64*2);
//				printf("%d %d\n", dut->DCT_OUTPUT[0][0], dut->DCT_OUTPUT[0][1] );
				for(int i=0;i<8;i++) {
					for(int j=0;j<8;j++) {
						v_y_data_result[(result_y_block_counter*64) + (i*8) + j] = dut->OUTPUT_DATA[i][j];
						//printf("%d ", v_y_data_result[(i*8) + j + (result_y_block_counter*64)]);
					}
				}
				//printf("\n");
				result_y_block_counter++;
				if (result_block_counter == 31) {
					v_y_data_result_flag = 1;
				}
			} else if (result_block_counter >= 32 && result_block_counter < 48) {
			//printf("%d %d\n", first,result_block_counter );
//				memcpy(&v_cb_data_result[result_cb_block_counter*64], dut->OUTPUT_DATA, 64*2);
				for(int i=0;i<8;i++) {
					for(int j=0;j<8;j++) {
						v_cb_data_result[(result_cb_block_counter*64) + (i*8) + j] = dut->OUTPUT_DATA[i][j];
						//printf("%d ", v_cb_data_result[(i*8)+ j + (result_cb_block_counter*64)]);
					}
				}
				//printf("\n");
				result_cb_block_counter++;
				if (result_block_counter == 47) {
					v_cb_data_result_flag = 1;
				}
			} else if (result_block_counter >= 48 && result_block_counter < 64) {
			//printf("%d %d\n", first,result_block_counter );
//				memcpy(&v_cr_data_result[result_cr_block_counter*64], dut->OUTPUT_DATA, 64*2);
				for(int i=0;i<8;i++) {
					for(int j=0;j<8;j++) {
						v_cr_data_result[(result_cr_block_counter*64) + (i*8) + j] = dut->OUTPUT_DATA[i][j];
						//printf("%d ", v_cr_data_result[(i*8)+ j + (result_cr_block_counter*64)]);
					}
				}
				//printf("\n");
				result_cr_block_counter++;
				if (result_block_counter == 63) {
					v_cr_data_result_flag = 1;
				}
			} else {
//				printf("end of dct %d %d %d %d %d\n", first , result_block_counter, result_y_block_counter, result_cb_block_counter, result_cr_block_counter);
			}
			result_block_counter++;
//			printf("result_block_counter %d\n",result_block_counter );
		}
	if (dut->VLC_RESET) {
		static  uint32_t start_offset;
		static uint16_t y_size = 0;
		static uint16_t cb_size = 0;

//		printf("%x %x\n", dut->DC_BITSTREAM_OUTPUT_ENABLE, dut->DC_BITSTREAM_SUM);
		if (vlc_state == Y_DC_STATE) {
			static int counter = 0;
			static int first = 1;
			if (first) {
				start_offset = getBitSize(slice_param[0].bitstream);
				first = 0;
			}
			if ((counter> 2) && (counter<32+3)) {
				//printf("%d %x\n", dut->LENGTH, dut->DC_BITSTREAM_SUM);
				setBit(slice_param[0].bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
			}
			counter++;

		} else if (vlc_state == Y_AC_STATE) {
			static int counter = 0;
			static uint32_t run_length=0;
			static uint32_t run_sum=0;
			static uint32_t run_length_n=0;
			static uint32_t run_sum_n=0;

			if (counter < 2017) {
				if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
//					printf("%d %x %x\n", dut->AC_BITSTREAM_RUN_LENGTH, dut->AC_BITSTREAM_RUN_SUM,  dut->AC_BITSTREAM_RUN_SUM_N,  dut->VAL,   dut->VAL_N);
					//printf("%d %x\n", dut->AC_BITSTREAM_RUN_LENGTH, dut->AC_BITSTREAM_RUN_SUM,  dut->AC_BITSTREAM_RUN_SUM_N,  dut->VAL,   dut->VAL_N);

				}
			}
			if (counter < 2018) {
#if 1
					//1clock前の値を代入する。
//				printf("%d %x\n", run_length, run_sum);
#endif
				//printf("level %d %x\n", dut->AC_BITSTREAM_LEVEL_OUTPUT_ENABLE, dut->AC_BITSTREAM_LEVEL_SUM);
				if (dut->AC_BITSTREAM_LEVEL_LENGTH) {
					//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
					run_length_n = run_length;
					run_sum_n = run_sum;
//					printf("%d %x\n", run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

					setBit(slice_param[0].bitstream, run_sum_n, run_length_n);
					setBit(slice_param[0].bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
				}
				if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
					run_length = dut->AC_BITSTREAM_RUN_LENGTH;
					run_sum = dut->AC_BITSTREAM_RUN_SUM;
				}
//				printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
			}

			counter++;

		}
		else if (vlc_state == CB_DC_STATE) {
			static int first = 1;
			if (first) {

				//end of y 
				uint32_t size  = getBitSize(slice_param[0].bitstream);
				if (size & 7 )  {
        			setBit(slice_param[0].bitstream, 0x0, 8 - (size % 8));
    			}
			    uint32_t current_offset = getBitSize(slice_param[0].bitstream);
				uint32_t vlc_size = (current_offset - start_offset)/8;
			    y_size  = SET_DATA16(vlc_size);

				start_offset = getBitSize(slice_param[0].bitstream);
				first = 0;

			}

			static int counter = 0;
			if ((counter> 2) && (counter<16+3)) {
				//printf("%d %x\n", dut->LENGTH, dut->DC_BITSTREAM_SUM);
				setBit(slice_param[0].bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
			}
			counter++;

		} else if (vlc_state == CB_AC_STATE) {
			static int counter = 0;
			static uint32_t run_length=0;
			static uint32_t run_sum=0;
			static uint32_t run_length_n=0;
			static uint32_t run_sum_n=0;
			//printf("counter %d %d\n", counter,dut->AC_BITSTREAM_LEVEL_LENGTH);
			if (counter < 1009) {
				if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
//					printf("%d %x %x\n", dut->AC_BITSTREAM_RUN_LENGTH, dut->AC_BITSTREAM_RUN_SUM,  dut->AC_BITSTREAM_RUN_SUM_N,  dut->VAL,   dut->VAL_N);
					//printf("%d %x\n", dut->AC_BITSTREAM_RUN_LENGTH, dut->AC_BITSTREAM_RUN_SUM,  dut->AC_BITSTREAM_RUN_SUM_N,  dut->VAL,   dut->VAL_N);

				}
			}
			if (counter < 1010) {
#if 1
					//1clock前の値を代入する。
//				printf("%d %x\n", run_length, run_sum);
#endif
				//printf("level %d %x\n", dut->AC_BITSTREAM_LEVEL_OUTPUT_ENABLE, dut->AC_BITSTREAM_LEVEL_SUM);
//				printf("%d %x\n", run_length_n, run_sum_n);
//				printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
				if (dut->AC_BITSTREAM_LEVEL_LENGTH) {
					//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
					run_length_n = run_length;
					run_sum_n = run_sum;
//					printf("%d %x\n", run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
					//printf("%d %x\n", run_length_n, run_sum_n);
					//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

					setBit(slice_param[0].bitstream, run_sum_n, run_length_n);
					setBit(slice_param[0].bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
				}
				if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
					run_length = dut->AC_BITSTREAM_RUN_LENGTH;
					run_sum = dut->AC_BITSTREAM_RUN_SUM;
				}
//				printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
			} 
			counter++;
		} else if (vlc_state == CR_DC_STATE) {
			static int first = 1;
			if (first) {

				//end of cb
				uint32_t size  = getBitSize(slice_param[0].bitstream);
				if (size & 7 )  {
        			setBit(slice_param[0].bitstream, 0x0, 8 - (size % 8));
    			}
			    uint32_t current_offset = getBitSize(slice_param[0].bitstream);
				uint32_t vlc_size = (current_offset - start_offset)/8;
			    cb_size  = SET_DATA16(vlc_size);

				start_offset = getBitSize(slice_param[0].bitstream);
				first = 0;

			}


			static int counter = 0;
			if ((counter> 2) && (counter<16+3)) {
				//printf("%d %x\n", dut->LENGTH, dut->DC_BITSTREAM_SUM);
				setBit(slice_param[0].bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
			}
			counter++;

		} else if (vlc_state == CR_AC_STATE) {
			static int counter = 0;
			static uint32_t run_length=0;
			static uint32_t run_sum=0;
			static uint32_t run_length_n=0;
			static uint32_t run_sum_n=0;

			if (counter < 1009) {
				if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
//					printf("%d %x %x\n", dut->AC_BITSTREAM_RUN_LENGTH, dut->AC_BITSTREAM_RUN_SUM,  dut->AC_BITSTREAM_RUN_SUM_N,  dut->VAL,   dut->VAL_N);
					//printf("%d %x\n", dut->AC_BITSTREAM_RUN_LENGTH, dut->AC_BITSTREAM_RUN_SUM,  dut->AC_BITSTREAM_RUN_SUM_N,  dut->VAL,   dut->VAL_N);

				}
			}
			if (counter < 1010) {
#if 1
					//1clock前の値を代入する。
//				printf("%d %x\n", run_length, run_sum);
#endif
				//printf("level %d %x\n", dut->AC_BITSTREAM_LEVEL_OUTPUT_ENABLE, dut->AC_BITSTREAM_LEVEL_SUM);
				if (dut->AC_BITSTREAM_LEVEL_LENGTH) {
					//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
					run_length_n = run_length;
					run_sum_n = run_sum;
					//printf("%d %x\n", run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

					setBit(slice_param[0].bitstream, run_sum_n, run_length_n);
					setBit(slice_param[0].bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
				}
				if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
					run_length = dut->AC_BITSTREAM_RUN_LENGTH;
					run_sum = dut->AC_BITSTREAM_RUN_SUM;
				}
//				printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
			}
			counter++;

		} else if (vlc_state == END_STATE) {
			static int first = 1;
			if (first) {

				//end of cr
				uint32_t size  = getBitSize(slice_param[0].bitstream);
				if (size & 7 )  {
	       			setBit(slice_param[0].bitstream, 0x0, 8 - (size % 8));
	   			}
	#if 1
			    setByteInOffset(slice_param[0].bitstream, code_size_of_y_data_offset , (uint8_t *)&y_size, 2);
	    		setByteInOffset(slice_param[0].bitstream, code_size_of_cb_data_offset , (uint8_t *)&cb_size, 2);
	    		uint32_t current_offset = getBitSize(slice_param[0].bitstream);
				//printf("size=0x%x\n",  ((current_offset - slice_start_offset)/8));
	    		uint32_t slice_size =  ((current_offset - slice_start_offset)/8);
				write_slice_size(slice_param[0].slice_no, slice_size);
				setByte(&write_bitstream, slice_param[0].bitstream->bitstream_buffer, slice_size);
		        setSliceTalbeFlush(slice_size_table[0], slice_size_table_offset);

			    uint32_t picture_end = (getBitSize(&write_bitstream)) >>  3 ;

			    uint32_t tmp  = picture_end - picture_size_offset;
			    uint32_t picture_size = SET_DATA32(tmp);

			    setByteInOffset(&write_bitstream, picture_size_offset_, (uint8_t*)&picture_size, 4);

				uint32_t encode_frame_size;
	   			 uint8_t *ptr = getBitStream(&write_bitstream, &encode_frame_size);
			    uint32_t frame_size_data = SET_DATA32(encode_frame_size);
			    setByteInOffset(&write_bitstream, frame_size_offset, (uint8_t*)&frame_size_data , 4);

		        size_t writesize = fwrite(ptr, 1, encode_frame_size,  slice_output);
	    	    if (writesize != encode_frame_size) {
	        	    printf("%s %d %d\n", __FUNCTION__, __LINE__, (int)writesize);
	            	//printf("write %d %p %d %p \n", (int)writesize, raw_data, raw_size,output);
	            	//return -1;
	        	}
				fclose(slice_output);
				first = 0;
			}
#endif
		}

#if 0
		printf("VLC_RESET %d\n", dut->VLC_RESET);
		printf("ABS_PREVIOUSDCDIFF %d\n", dut->ABS_PREVIOUSDCDIFF);
		printf("ABS_PREVIOUSDCDIFF_NEXT %d\n", dut->ABS_PREVIOUSDCDIFF_NEXT);
		printf("PREVIOUSDCOEFF %d\n", dut->PREVIOUSDCOEFF);
		printf("PREVIOUSDCDIFF %d\n", dut->PREVIOUSDCDIFF);
		printf("DC_COEFF_DIFFERENCE %d\n", dut->DC_COEFF_DIFFERENCE);
		printf("VAL %d\n", dut->VAL);
		printf("VAL_N %d\n", dut->VAL_N);
		printf("is_expo_golomb_code %d\n", dut->is_expo_golomb_code);
		printf("INPUT_DC_DATA %d\n", dut->INPUT_DC_DATA);
		printf("LENGTH %d\n", dut->LENGTH);
		printf("is_add_setbit %d\n", dut->is_add_setbit);
		printf("k %d\n", dut->k);

#endif
	} else {

//		printf("VLC_RESET %d\n", dut->VLC_RESET);
	}
#if 0
LENGTH,
ABS_PREVIOUSDCDIFF,
ABS_PREVIOUSDCDIFF_NEXT,
PREVIOUSDCOEFF,
PREVIOUSDCDIFF,
DC_COEFF_DIFFERENCE,
VAL,
VAL_N
#endif

}
static int block_counter = 0;
static int block_cb_counter = 0;
static int block_cr_counter = 0;

static int vlc_counter = 0;

extern uint8_t block_pattern_scan_read_order_table[64];

void posedge_clock(Vwrapper *dut){
#if 0
	static int first = 1;
	if (first ) {
		print_block16(v_y_data);
	}
	first=0;
#endif
	if (block_counter < 32) {
		int i,j;
		for(i=0;i<8;i++) {
			for(j=0;j<8;j++) {
				dut->INPUT_DATA[i][j] = (int32_t)v_y_data[((i*8)+j)+ block_counter * 64];

			}
		}
		static int first =0;
		if (first) {
		int i,j;
		for(i=0;i<8;i++) {
			for(j=0;j<8;j++) {
				printf("%d ", dut->INPUT_DATA[i][j]);

			}
		}
		printf("\n");
		}
		first=0;

		
	} else if (block_counter <48) {
		int i,j;
		for(i=0;i<8;i++) {
			for(j=0;j<8;j++) {
				dut->INPUT_DATA[i][j] = (int32_t)v_cb_data[((i*8)+j)+ block_cb_counter * 64];

			}
		}
		block_cb_counter++;
	} else if (block_counter  < 64) {
		int i,j;
		for(i=0;i<8;i++) {
			for(j=0;j<8;j++) {
				dut->INPUT_DATA[i][j] = (int32_t)v_cr_data[((i*8)+j)+ block_cr_counter * 64];

			}
		}
		block_cr_counter++;
	}

	block_counter++;
	if (block_counter >= 64) {
		//block_counter = 0;
	}

	dut->QSCALE = qscale_table_[0];
	int i,j;
	for(i=0;i<8;i++) {
		for(j=0;j<8;j++) {
			dut->QMAT[i][j] = luma_matrix2_[(i*8)+j];
			

		}
	}
#if 0
	static int first3 = 1;
	if (first3 ) {
		printf("q %d\n",qscale_table_[0] );
		print_block8((int8_t*)luma_matrix2_);
	}
	first3=0;
#endif
	if (v_cb_data_result_flag == 1) {
		if (vlc_state == 0) {
			vlc_state = Y_DC_RESET_STATE;
			vlc_counter = 0;
		} else if (vlc_state == Y_DC_RESET_STATE) {
			dut->VLC_RESET = 0;
			vlc_state = Y_DC_STATE;
		} else if (vlc_state == Y_DC_STATE) {
			static int first =1;
			if (first) {
				dut->VLC_RESET = 1;
				vlc_counter = 0;
				first = 0;
			}

			dut->INPUT_DC_DATA = v_y_data_result[(vlc_counter*64)%(32*64)];

			if (vlc_counter == 31+12) {
				vlc_state = Y_AC_RESET_STATE;
			}
		} else if (vlc_state == Y_AC_RESET_STATE) {
			dut->VLC_RESET = 0;
			vlc_state = Y_AC_STATE;

		} else if (vlc_state == Y_AC_STATE) {
			static int first =1;
			static int conefficient = 1;
			static int block = 0;
			static int position;

			if (first) {
				dut->VLC_RESET = 1;
				vlc_counter = 0;
				first = 0;
			}
			if (block == 0) {
	        	position = block_pattern_scan_read_order_table[conefficient%64];
			}

			//128x16x2
//			if ((block * 64) + position > (128*16*2))
			//printf("p %d %d %d\n", (block * 64) + position, block,position,conefficient);
			if (conefficient < 64) {
				dut->INPUT_AC_DATA = v_y_data_result[(block * 64) + position];
			}  else {
				dut->INPUT_AC_DATA = 1;
			}
			//printf("conefficient %d\n", conefficient);

			block++;
			if (block == 32) {
				block = 0;
				conefficient++;
			}

			if (conefficient == 65) {
				vlc_state = CB_DC_RESET_STATE;
				//printf("end of y ac\n");
			}
		} else if (vlc_state == CB_DC_RESET_STATE) {
			dut->VLC_RESET = 0;
			vlc_state = CB_DC_STATE;
		} else if (vlc_state == CB_DC_STATE) {
			static int first =1;
			if (first) {
				dut->VLC_RESET = 1;
				vlc_counter = 0;
				first = 0;
			}

			dut->INPUT_DC_DATA = v_cb_data_result[(vlc_counter*64)%(16*64)];

			if (vlc_counter == 31+12) {
				vlc_state = CB_AC_RESET_STATE;
			}
		} else if (vlc_state == CB_AC_RESET_STATE) {
			dut->VLC_RESET = 0;
			vlc_state = CB_AC_STATE;

		} else if (vlc_state == CB_AC_STATE) {
			static int first =1;
			static int conefficient = 1;
			static int block = 0;
			static int position;

			if (first) {
				dut->VLC_RESET = 1;
				vlc_counter = 0;
				first = 0;
			}
			if (block == 0) {
	        	position = block_pattern_scan_read_order_table[conefficient%64];
			}

			//128x16x2
//			if ((block * 64) + position > (128*16*2))
			//printf("p %d %d %d\n", (block * 64) + position, block,position,conefficient);
			if (conefficient < 64) {
				dut->INPUT_AC_DATA = v_cb_data_result[(block * 64) + position];
			}  else {
				dut->INPUT_AC_DATA = 1;
			}
			//printf("val %d\n", dut->INPUT_AC_DATA);
			//printf("conefficient %d\n", conefficient);

			block++;
			if (block == 16) {
				block = 0;
				conefficient++;
			}

			if (conefficient == 65) {
				vlc_state = CR_DC_RESET_STATE;
				//printf("end of y ac\n");
			}
		}else if (vlc_state == CR_DC_RESET_STATE) {
			dut->VLC_RESET = 0;
			vlc_state = CR_DC_STATE;
		} else if (vlc_state == CR_DC_STATE) {
			static int first =1;
			if (first) {
				dut->VLC_RESET = 1;
				vlc_counter = 0;
				first = 0;
			}

			dut->INPUT_DC_DATA = v_cr_data_result[(vlc_counter*64)%(16*64)];
			//printf("val %d\n",dut->INPUT_DC_DATA);
			if (vlc_counter == 31+12) {
				vlc_state = CR_AC_RESET_STATE;
			}
		} else if (vlc_state == CR_AC_RESET_STATE) {
			dut->VLC_RESET = 0;
			vlc_state = CR_AC_STATE;

		} else if (vlc_state == CR_AC_STATE) {
			static int first =1;
			static int conefficient = 1;
			static int block = 0;
			static int position;

			if (first) {
				dut->VLC_RESET = 1;
				vlc_counter = 0;
				first = 0;
			}
			if (block == 0) {
	        	position = block_pattern_scan_read_order_table[conefficient%64];
			}

			//128x16x2
//			if ((block * 64) + position > (128*16*2))
			//printf("p %d %d %d\n", (block * 64) + position, block,position,conefficient);
			if (conefficient < 64) {
				dut->INPUT_AC_DATA = v_cr_data_result[(block * 64) + position];
			}  else {
				dut->INPUT_AC_DATA = 1;
			}
			//printf("conefficient %d\n", conefficient);

			block++;
			if (block == 16) {
				block = 0;
				conefficient++;
			}

			if (conefficient == 65) {
				vlc_state = END_STATE;
				//printf("end of y ac\n");
			}
		} else if (vlc_state == END_STATE) {

		}

	//	printf("state %d\n", vlc_state);
		
		vlc_counter++;
	}

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

void init_test(Vwrapper *dut) {
//	vlc_init();
}

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
#if 0
	if (argc != 5) {
		printf("error %d", __LINE__);
		return -1;
	}
	in=fopen(argv[1], "r");
	if (in == NULL) {
		printf("argv[1] %s", argv[1]);
		return -1;
	} 
	out=fopen(argv[2], "w");
	if (out == NULL) {
		printf("argv[2] %s", argv[2]);
		return -1;
	}
	char buf[1024];
	char *ptr;
	for(int i=0;i<64;i++) {
		ptr = fgets(buf,1024, in);
		org[i] = atoi(buf);
	}
	fclose(in);

	width = atoi(argv[3]);
	height = atoi(argv[4]);
#else

#endif
	return 0;
}


void toggle_clock(Vwrapper *dut) {
	dut->CLOCK = !dut->CLOCK; // Toggle clock
//	dut->eval();

}