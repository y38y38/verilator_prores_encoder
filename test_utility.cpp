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


int16_t v_data_result[128*16*2];

int result_block_counter =0;

int result_y_block_counter =0;
int result_cb_block_counter =0;
int result_cr_block_counter =0;


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

void set_result_dct_data(int16_t *data, Vwrapper *dut) {
	for(int i=0;i<8;i++) {
		for(int j=0;j<8;j++) {
			data[ (i*8) + j] = dut->OUTPUT_DATA[i][j];
			//printf("%d ", v_y_data_result[(i*8) + j + (result_y_block_counter*64)]);
		}
	}
}

void posedge_clock_result(Vwrapper *dut){
		static int first = 1;
		first++;
		if (first>=12) {
			if (result_block_counter>=0 && result_block_counter<32) {

				set_result_dct_data(&v_y_data_result[(result_y_block_counter*64)], dut);
				result_y_block_counter++;

			} else if (result_block_counter >= 32 && result_block_counter < 48) {
				set_result_dct_data(&v_cb_data_result[(result_cb_block_counter*64)], dut);
				result_cb_block_counter++;

			} else if (result_block_counter >= 48 && result_block_counter < 64) {
				set_result_dct_data(&v_cr_data_result[(result_cr_block_counter*64)], dut);
				result_cr_block_counter++;

				if (result_block_counter == 63) {
					v_cr_data_result_flag = 1;
				}
			}
			result_block_counter++;
//			printf("result_block_counter %d\n",result_block_counter );
		}

	if (dut->VLC_RESET) {

		static int component = 0;
		static  uint32_t start_offset;
		static uint16_t y_size = 0;
		static uint16_t cb_size = 0;


		if ((vlc_state == Y_DC_STATE) 
			||(vlc_state == CB_DC_STATE) 
			||(vlc_state == CR_DC_STATE) 
			){
			static int counter = 0;
			static int y_first = 1;
			static int cb_first = 1;
			static int cr_first = 1;
			if (vlc_state == Y_DC_STATE) {
				if (y_first) {
					start_offset = getBitSize(slice_param[0].bitstream);
					y_first = 0;
					counter = 0;
				}
			} else if (vlc_state == CB_DC_STATE) {

				if (cb_first) {
					//end of y 
					uint32_t size  = getBitSize(slice_param[0].bitstream);
					if (size & 7 )  {
        				setBit(slice_param[0].bitstream, 0x0, 8 - (size % 8));
    				}
					//printf("size=%d %d %d\n", size, start_offset, size - start_offset);
				    uint32_t current_offset = getBitSize(slice_param[0].bitstream);
					printf("end of y %d\n", current_offset);
					uint32_t vlc_size = (current_offset - start_offset)/8;
				    y_size  = SET_DATA16(vlc_size);


					component++;
					start_offset = getBitSize(slice_param[0].bitstream);
					cb_first = 0;
					counter = 0;

				}
			} else if (vlc_state == CR_DC_STATE) {
				if (cr_first) {
					//end of cb
					uint32_t size  = getBitSize(slice_param[0].bitstream);
					if (size & 7 )  {
   	     				setBit(slice_param[0].bitstream, 0x0, 8 - (size % 8));
   					}
				    uint32_t current_offset = getBitSize(slice_param[0].bitstream);
					uint32_t vlc_size = (current_offset - start_offset)/8;
			   		cb_size  = SET_DATA16(vlc_size);

					component++;
					start_offset = getBitSize(slice_param[0].bitstream);
					cr_first = 0;
					counter = 0;
				}

			}

			if (component == 0) {
				if ((counter> 2) && (counter<32+3)) {
					//printf("%d \n", getBitSize(slice_param[0].bitstream));
					setBit(slice_param[0].bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
					//printf("%d %x\n", dut->LENGTH, dut->DC_BITSTREAM_SUM);
//					counter = 0;
//					first = 1;
				}
			} else if (component == 1) {
				if ((counter> 2) && (counter<16+3)) {
					//printf("%d %x\n", dut->LENGTH, dut->DC_BITSTREAM_SUM);
					setBit(slice_param[0].bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
//					counter = 0;
				//	first = 1;
				}

			} else if (component == 2) {
				if ((counter> 2) && (counter<16+3)) {
					//printf("%d %x\n", dut->LENGTH, dut->DC_BITSTREAM_SUM);
					setBit(slice_param[0].bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
//					counter = 0;
				//	first = 1;
				}

			}
			counter++;

		} else if ((vlc_state == Y_AC_STATE)
					||(vlc_state == CB_AC_STATE) 
					||(vlc_state == CR_AC_STATE)
		 			){
			static int y_first = 1;
			static int cb_first = 1;
			static int cr_first = 1;
			static int counter = 0;


			if (vlc_state == Y_AC_STATE) {
				if (y_first) {
					counter = 0;
					y_first = 0;
				}
			}else if (vlc_state == CB_AC_STATE) {
				if (cb_first) {
					counter = 0;
					cb_first = 0;
				}
			}else if (vlc_state == CR_AC_STATE) {
				if (cr_first) {
					counter = 0;
					cr_first = 0;
				}

			}

			static uint32_t run_length=0;
			static uint32_t run_sum=0;
			static uint32_t run_length_n=0;
			static uint32_t run_sum_n=0;

			if (component == 0) {
				if (counter < 2018) {
					//printf("level %d %x\n", dut->AC_BITSTREAM_LEVEL_OUTPUT_ENABLE, dut->AC_BITSTREAM_LEVEL_SUM);
					if (dut->AC_BITSTREAM_LEVEL_LENGTH) {
						//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
						run_length_n = run_length;
						run_sum_n = run_sum;
							//printf("%d %x\n", run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

						setBit(slice_param[0].bitstream, run_sum_n, run_length_n);
						setBit(slice_param[0].bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
						printf("%x\n", dut->AC_BITSTREAM_LEVEL_SUM);
					}
					if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
						run_length = dut->AC_BITSTREAM_RUN_LENGTH;
						run_sum = dut->AC_BITSTREAM_RUN_SUM;
					}
					//	printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
				}

			} else if (component == 1) {
				if (counter < 1010) {
					//printf("level %d %x\n", dut->AC_BITSTREAM_LEVEL_OUTPUT_ENABLE, dut->AC_BITSTREAM_LEVEL_SUM);
					if (dut->AC_BITSTREAM_LEVEL_LENGTH) {
						//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
						run_length_n = run_length;
						run_sum_n = run_sum;
						//	printf("%d %x\n", run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

						setBit(slice_param[0].bitstream, run_sum_n, run_length_n);
						setBit(slice_param[0].bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
					}
					if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
						run_length = dut->AC_BITSTREAM_RUN_LENGTH;
						run_sum = dut->AC_BITSTREAM_RUN_SUM;
					}
						//printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

				}
			} else if (component == 2) {
				if (counter < 1010) {
					//printf("level %d %x\n", dut->AC_BITSTREAM_LEVEL_OUTPUT_ENABLE, dut->AC_BITSTREAM_LEVEL_SUM);
					if (dut->AC_BITSTREAM_LEVEL_LENGTH) {
						//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
						run_length_n = run_length;
						run_sum_n = run_sum;
						//	printf("%d %x\n", run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

						setBit(slice_param[0].bitstream, run_sum_n, run_length_n);
						setBit(slice_param[0].bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
					}
					if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
						run_length = dut->AC_BITSTREAM_RUN_LENGTH;
						run_sum = dut->AC_BITSTREAM_RUN_SUM;
					}
						//printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

				}
				
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
			    setByteInOffset(slice_param[0].bitstream, code_size_of_y_data_offset , (uint8_t *)&y_size, 2);
	    		setByteInOffset(slice_param[0].bitstream, code_size_of_cb_data_offset , (uint8_t *)&cb_size, 2);
	    		uint32_t current_offset = getBitSize(slice_param[0].bitstream);
				//printf("size=0x%x\n",  ((current_offset - slice_start_offset)/8));
	    		uint32_t slice_size =  ((current_offset - slice_start_offset)/8);
				write_slice_size(slice_param[0].slice_no, slice_size);
				printf("a %d \n", getBitSize(&write_bitstream));

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
printf("encode_frame_szize %d %p %p\n", encode_frame_size,ptr , slice_output);

		        size_t writesize = fwrite(ptr, 1, encode_frame_size,  slice_output);
	    	    if (writesize != encode_frame_size) {
	        	    printf("%s %d %d\n", __FUNCTION__, __LINE__, (int)writesize);
	            	//printf("write %d %p %d %p \n", (int)writesize, raw_data, raw_size,output);
	            	//return -1;
	        	}
				fclose(slice_output);
				first = 0;
			}
		}



	} else {
//		printf("VLC_RESET %d\n", dut->VLC_RESET);
	}

}
static int block_counter = 0;
static int block_cb_counter = 0;
static int block_cr_counter = 0;

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

void posedge_clock(Vwrapper *dut){
	if (block_counter < 32) {
		set_pixel_data(dut, &v_y_data[block_counter * 64]);
	} else if (block_counter <48) {
		set_pixel_data(dut, &v_cb_data[block_cb_counter * 64]);
		block_cb_counter++;
	} else if (block_counter  < 64) {
		set_pixel_data(dut, &v_cr_data[block_cr_counter * 64]);
		block_cr_counter++;
	}

	block_counter++;
	if (block_counter >= 64) {
		//block_counter = 0;
	}

	set_qscale(dut, qscale_table_[0]);
	set_qmatrix(dut, luma_matrix2_);




	if (v_cr_data_result_flag == 1) {
		static int component = 0;
//		static vlc_state2 = 0;

		if (vlc_state == 0) {
			if (component == 0) {
				vlc_state = Y_DC_RESET_STATE;
			} else if  (component == 1) {
				vlc_state = CB_DC_RESET_STATE;
			} else if  (component == 2) {
				vlc_state = CR_DC_RESET_STATE;
			}
			//vlc_counter = 0;
//				printf("state=%d %d\n", vlc_state, __LINE__);
		} else if ((vlc_state == Y_DC_RESET_STATE)
		 			|| (vlc_state == CB_DC_RESET_STATE) 
		 			|| (vlc_state == CR_DC_RESET_STATE) 
		 			) {
			dut->VLC_RESET = 0;
//			vlc_state = Y_DC_STATE;
			if (component == 0) {
				vlc_state = Y_DC_STATE;
			} else if  (component == 1) {
				vlc_state = CB_DC_STATE;
			} else if  (component == 2) {
				vlc_state = CR_DC_STATE;
			}
//				printf("state=%d %d\n", vlc_state, __LINE__);
		} else if ((vlc_state == Y_DC_STATE)
					|| (vlc_state == CB_DC_STATE)
					|| (vlc_state == CR_DC_STATE)
					){
			static int first =1;
			if (first) {
				dut->VLC_RESET = 1;
				vlc_counter = 0;
				first = 0;
			}

			if (component == 0) {
				dut->INPUT_DC_DATA = v_y_data_result[(vlc_counter*64)%(32*64)];
			} else if  (component == 1) {
				dut->INPUT_DC_DATA = v_cb_data_result[(vlc_counter*64)%(16*64)];
			} else if  (component == 2) {
				dut->INPUT_DC_DATA = v_cr_data_result[(vlc_counter*64)%(16*64)];
			}

			if (vlc_counter == 31+12) {
				if (component == 0) {
					vlc_state = Y_AC_RESET_STATE;
				} else if  (component == 1) {
					vlc_state = CB_AC_RESET_STATE;
				} else if  (component == 2) {
					vlc_state = CR_AC_RESET_STATE;
				}
				first=1;
//				printf("state=%d %d %d \n", vlc_state, __LINE__, component);
			}
		} else if ((vlc_state == Y_AC_RESET_STATE)
		 			|| (vlc_state == CB_AC_RESET_STATE) 
		 			|| (vlc_state == CR_AC_RESET_STATE) 
		 			) {
			dut->VLC_RESET = 0;
			vlc_state = Y_AC_STATE;
			if (component == 0) {
				vlc_state = Y_AC_STATE;
			} else if  (component == 1) {
				vlc_state = CB_AC_STATE;
			} else if  (component == 2) {
				vlc_state = CR_AC_STATE;
			}
//				printf("state=%d %d\n", vlc_state, __LINE__);
		} else if ((vlc_state == Y_AC_STATE)
		 			|| (vlc_state == CB_AC_STATE) 
		 			|| (vlc_state == CR_AC_STATE) 
		 			) {
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
//				dut->INPUT_AC_DATA = v_y_data_result[(block * 64) + position];

				if (component == 0) {
					dut->INPUT_AC_DATA = v_y_data_result[(block * 64) + position];
				} else if  (component == 1) {
					dut->INPUT_AC_DATA = v_cb_data_result[(block * 64) + position];
				} else if  (component == 2) {
					dut->INPUT_AC_DATA = v_cr_data_result[(block * 64) + position];
				}

			}  else {
				dut->INPUT_AC_DATA = 1;
			}
			//printf("conefficient %d\n", conefficient);

			block++;
			if (component == 0) {
				if (block == 32) {
					block = 0;
					conefficient++;
				}
			} else if  (component == 1) {
				if (block == 16) {
					block = 0;
					conefficient++;
				}
			} else if  (component == 2) {
				if (block == 16) {
					block = 0;
					conefficient++;
				}
			}

			if (conefficient == 65) {
//				vlc_state = CB_DC_RESET_STATE;
				//printf("end of y ac\n");
				if (component == 0) {
					vlc_state = CB_DC_RESET_STATE;
				} else if  (component == 1) {
					vlc_state = CR_DC_RESET_STATE;
				} else if  (component == 2) {
					vlc_state = END_STATE;
				}
				conefficient=1;
				block = 0;
				first = 1;
//				printf("state=%d %d\n", vlc_state, __LINE__);
				component++;

			}
		}
		vlc_counter++;
	}
//	printf("state=%d\n", vlc_state);

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
}


static int y_first1 = 1;
static int y_first2 = 1;
		static int result_first = 1;

void init_test(Vwrapper *dut) {
//	vlc_init();
	block_counter = 0;
	result_block_counter = 0;
	y_first1 = 1;
	y_first2 = 1;
vlc_state = 0;
v_cr_data_result_flag=0;
result_first = 1;
}




void posedge_clock_v(int16_t *pixel, Vwrapper *dut, int block_num){
	int component = 0;
	if (block_counter < block_num) {
		set_pixel_data(dut, &pixel[block_counter * 64]);
	}
#if 0
	 else if (block_counter <48) {
		set_pixel_data(dut, &v_cb_data[block_cb_counter * 64]);
		block_cb_counter++;
	} else if (block_counter  < 64) {
		set_pixel_data(dut, &v_cr_data[block_cr_counter * 64]);
		block_cr_counter++;
	}
#endif
	block_counter++;
//	if (block_counter >= 64) {
		//block_counter = 0;
//	}

	set_qscale(dut, qscale_table_[0]);
	set_qmatrix(dut, luma_matrix2_);

	if (v_cr_data_result_flag == 1) {
//		static vlc_state2 = 0;

		if (vlc_state == 0) {
			if (component == 0) {
				vlc_state = Y_DC_RESET_STATE;
			} else if  (component == 1) {
				vlc_state = CB_DC_RESET_STATE;
			} else if  (component == 2) {
				vlc_state = CR_DC_RESET_STATE;
			}
			//vlc_counter = 0;
//				printf("state=%d %d\n", vlc_state, __LINE__);
		} else if ((vlc_state == Y_DC_RESET_STATE)
		 			|| (vlc_state == CB_DC_RESET_STATE) 
		 			|| (vlc_state == CR_DC_RESET_STATE) 
		 			) {
			dut->VLC_RESET = 0;
//			vlc_state = Y_DC_STATE;
			if (component == 0) {
				vlc_state = Y_DC_STATE;
			} else if  (component == 1) {
				vlc_state = CB_DC_STATE;
			} else if  (component == 2) {
				vlc_state = CR_DC_STATE;
			}
//				printf("state=%d %d\n", vlc_state, __LINE__);
		} else if ((vlc_state == Y_DC_STATE)
					|| (vlc_state == CB_DC_STATE)
					|| (vlc_state == CR_DC_STATE)
					){
			static int first =1;
			if (first) {
				dut->VLC_RESET = 1;
				vlc_counter = 0;
				first = 0;
			}

//			if (component == 0) {
			dut->INPUT_DC_DATA = v_data_result[(vlc_counter*64)%(block_num*64)];
#if 0
			} else if  (component == 1) {
				dut->INPUT_DC_DATA = v_cb_data_result[(vlc_counter*64)%(16*64)];
			} else if  (component == 2) {
				dut->INPUT_DC_DATA = v_cr_data_result[(vlc_counter*64)%(16*64)];
			}
#endif
			if (vlc_counter == 31+12) {
				if (component == 0) {
					vlc_state = Y_AC_RESET_STATE;
				} else if  (component == 1) {
					vlc_state = CB_AC_RESET_STATE;
				} else if  (component == 2) {
					vlc_state = CR_AC_RESET_STATE;
				}
				first=1;
//				printf("state=%d %d %d \n", vlc_state, __LINE__, component);
			}
		} else if ((vlc_state == Y_AC_RESET_STATE)
		 			|| (vlc_state == CB_AC_RESET_STATE) 
		 			|| (vlc_state == CR_AC_RESET_STATE) 
		 			) {
			dut->VLC_RESET = 0;
			vlc_state = Y_AC_STATE;
			if (component == 0) {
				vlc_state = Y_AC_STATE;
			} else if  (component == 1) {
				vlc_state = CB_AC_STATE;
			} else if  (component == 2) {
				vlc_state = CR_AC_STATE;
			}
//				printf("state=%d %d\n", vlc_state, __LINE__);
		} else if ((vlc_state == Y_AC_STATE)
		 			|| (vlc_state == CB_AC_STATE) 
		 			|| (vlc_state == CR_AC_STATE) 
		 			) {
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
//				dut->INPUT_AC_DATA = v_y_data_result[(block * 64) + position];
#if 0
				if (component == 0) {
					dut->INPUT_AC_DATA = v_y_data_result[(block * 64) + position];
				} else if  (component == 1) {
					dut->INPUT_AC_DATA = v_cb_data_result[(block * 64) + position];
				} else if  (component == 2) {
					dut->INPUT_AC_DATA = v_cr_data_result[(block * 64) + position];
				}
#else
				dut->INPUT_AC_DATA = v_data_result[(block * 64) + position];

#endif
			}  else {
				dut->INPUT_AC_DATA = 1;
			}
			//printf("conefficient %d\n", conefficient);

			block++;
#if 0
			if (component == 0) {
				if (block == 32) {
					block = 0;
					conefficient++;
				}
			} else if  (component == 1) {
				if (block == 16) {
					block = 0;
					conefficient++;
				}
			} else if  (component == 2) {
				if (block == 16) {
					block = 0;
					conefficient++;
				}
			}
#else
				if (block == block_num) {
					block = 0;
					conefficient++;
				}

#endif
			if (conefficient == 65) {
//				vlc_state = CB_DC_RESET_STATE;
				//printf("end of y ac\n");
				if (component == 0) {
					vlc_state = END_STATE;
				} else if  (component == 1) {
					vlc_state = CR_DC_RESET_STATE;
				} else if  (component == 2) {
					vlc_state = END_STATE;
				}
				conefficient=1;
				block = 0;
				first = 1;
//				printf("state=%d %d\n", vlc_state, __LINE__);
				component++;

			}
		}
		vlc_counter++;
	}
//	printf("state=%d\n", vlc_state);

}

void posedge_clock_result_v(Vwrapper *dut, struct bitstream *bitstream, int block_num) {
		result_first++;
		if (result_first>=12) {
#if 0
			if (result_block_counter>=0 && result_block_counter<32) {

				set_result_dct_data(&v_y_data_result[(result_y_block_counter*64)], dut);
				result_y_block_counter++;

			} else if (result_block_counter >= 32 && result_block_counter < 48) {
				set_result_dct_data(&v_cb_data_result[(result_cb_block_counter*64)], dut);
				result_cb_block_counter++;

			} else if (result_block_counter >= 48 && result_block_counter < 64) {
				set_result_dct_data(&v_cr_data_result[(result_cr_block_counter*64)], dut);
				result_cr_block_counter++;

				if (result_block_counter == 63) {
					v_cr_data_result_flag = 1;
				}
			}
			result_block_counter++;
//			printf("result_block_counter %d\n",result_block_counter );
#else
			if (result_block_counter>=0 && result_block_counter<block_num) {

				set_result_dct_data(&v_data_result[(result_block_counter*64)], dut);
				result_block_counter++;
				if (result_block_counter == (block_num-1)) {
					v_cr_data_result_flag = 1;
					//printf("flag!\n");
				}
					//printf("flag!\n");

			}

#endif
		}

	if (dut->VLC_RESET) {
//		printf("aa\n");
		int component = 0;
		static  uint32_t start_offset;
		static uint16_t y_size = 0;
		static uint16_t cb_size = 0;


		if ((vlc_state == Y_DC_STATE) 
			||(vlc_state == CB_DC_STATE) 
			||(vlc_state == CR_DC_STATE) 
			){
			static int counter = 0;
//			static int cb_first = 1;
//			static int cr_first = 1;

			if (vlc_state == Y_DC_STATE) {
				if (y_first1) {
					start_offset = getBitSize(bitstream);
					y_first1 = 0;
					counter = 0;
				}
			} else if (vlc_state == CB_DC_STATE) {
printf("eeror\n");
#if 1
		int cb_first;
				if (cb_first) {
					//end of y 
					uint32_t size  = getBitSize(bitstream);
					if (size & 7 )  {
        				setBit(bitstream, 0x0, 8 - (size % 8));
    				}
				    uint32_t current_offset = getBitSize(bitstream);

					uint32_t vlc_size = (current_offset - start_offset)/8;
				    y_size  = SET_DATA16(vlc_size);


					component++;
					start_offset = getBitSize(bitstream);
					cb_first = 0;
					counter = 0;

				}
#endif
			} else if (vlc_state == CR_DC_STATE) {
printf("eeror\n");
#if 1
int cr_first;
				if (cr_first) {
					//end of cb
					uint32_t size  = getBitSize(bitstream);
					if (size & 7 )  {
   	     				setBit(bitstream, 0x0, 8 - (size % 8));
   					}
				    uint32_t current_offset = getBitSize(bitstream);
					uint32_t vlc_size = (current_offset - start_offset)/8;
			   		cb_size  = SET_DATA16(vlc_size);

					component++;
					start_offset = getBitSize(bitstream);
					cr_first = 0;
					counter = 0;
				}
#endif
			}

			if (component == 0) {
				if ((counter> 2) && (counter<(block_num+3))) {
					setBit(bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
					//printf("%d %x\n", dut->LENGTH, dut->DC_BITSTREAM_SUM);
					//printf("%d\n", dut->DC_BITSTREAM_SUM);
//					counter = 0;
//					first = 1;
				}
			} else if (component == 1) {
				if ((counter> 2) && (counter<16+3)) {
					//printf("%d %x\n", dut->LENGTH, dut->DC_BITSTREAM_SUM);
					setBit(bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
//					counter = 0;
				//	first = 1;
				}

			} else if (component == 2) {
				if ((counter> 2) && (counter<16+3)) {
					//printf("%d %x\n", dut->LENGTH, dut->DC_BITSTREAM_SUM);
					setBit(bitstream, dut->DC_BITSTREAM_SUM, dut->LENGTH);
//					counter = 0;
				//	first = 1;
				}

			}
			counter++;

		} else if ((vlc_state == Y_AC_STATE)
					||(vlc_state == CB_AC_STATE) 
					||(vlc_state == CR_AC_STATE)
		 			){
			static int cb_first = 1;
			static int cr_first = 1;
			static int counter = 0;


			if (vlc_state == Y_AC_STATE) {
				if (y_first2) {
					counter = 0;
					y_first2 = 0;
				}
			}else if (vlc_state == CB_AC_STATE) {
				if (cb_first) {
					counter = 0;
					cb_first = 0;
				}
			}else if (vlc_state == CR_AC_STATE) {
				if (cr_first) {
					counter = 0;
					cr_first = 0;
				}

			}

			static uint32_t run_length=0;
			static uint32_t run_sum=0;
			static uint32_t run_length_n=0;
			static uint32_t run_sum_n=0;

			if (component == 0) {
				if (counter < ((block_num * 63) +2)) {
					//printf("level %d %x\n", dut->AC_BITSTREAM_LEVEL_OUTPUT_ENABLE, dut->AC_BITSTREAM_LEVEL_SUM);
					if (dut->AC_BITSTREAM_LEVEL_LENGTH) {
						//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
						run_length_n = run_length;
						run_sum_n = run_sum;
							//printf("%d %x\n", run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

						setBit(bitstream, run_sum_n, run_length_n);
						setBit(bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
						if (block_num==32) {
							//printf("%x\n", dut->AC_BITSTREAM_LEVEL_SUM);

						}
					}
					if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
						run_length = dut->AC_BITSTREAM_RUN_LENGTH;
						run_sum = dut->AC_BITSTREAM_RUN_SUM;
					}
					//	printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
				}

			} else if (component == 1) {
				if (counter < 1010) {
					//printf("level %d %x\n", dut->AC_BITSTREAM_LEVEL_OUTPUT_ENABLE, dut->AC_BITSTREAM_LEVEL_SUM);
					if (dut->AC_BITSTREAM_LEVEL_LENGTH) {
						//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
						run_length_n = run_length;
						run_sum_n = run_sum;
						//	printf("%d %x\n", run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

						setBit(bitstream, run_sum_n, run_length_n);
						setBit(bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
					}
					if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
						run_length = dut->AC_BITSTREAM_RUN_LENGTH;
						run_sum = dut->AC_BITSTREAM_RUN_SUM;
					}
						//printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

				}
			} else if (component == 2) {
				if (counter < 1010) {
					//printf("level %d %x\n", dut->AC_BITSTREAM_LEVEL_OUTPUT_ENABLE, dut->AC_BITSTREAM_LEVEL_SUM);
					if (dut->AC_BITSTREAM_LEVEL_LENGTH) {
						//printf("%d %x\n", dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);
						run_length_n = run_length;
						run_sum_n = run_sum;
						//	printf("%d %x\n", run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

						setBit(bitstream, run_sum_n, run_length_n);
						setBit(bitstream, dut->AC_BITSTREAM_LEVEL_SUM, dut->AC_BITSTREAM_LEVEL_LENGTH);
					}
					if (dut->AC_BITSTREAM_RUN_OUTPUT_ENABLE) {
						run_length = dut->AC_BITSTREAM_RUN_LENGTH;
						run_sum = dut->AC_BITSTREAM_RUN_SUM;
					}
						//printf("%d %x %d %x %d %x\n", run_length, run_sum, run_length_n, run_sum_n, dut->AC_BITSTREAM_LEVEL_LENGTH, dut->AC_BITSTREAM_LEVEL_SUM);

				}
				
			}

			counter++;

		} else if (vlc_state == END_STATE) {
			static int first = 1;
			if (first) {
#if 0

				//end of cr
				uint32_t size  = getBitSize(slice_param[0].bitstream);
				if (size & 7 )  {
	       			setBit(slice_param[0].bitstream, 0x0, 8 - (size % 8));
	   			}
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
printf("encode_frame_szize %d %p %p\n", encode_frame_size,ptr , slice_output);
		        size_t writesize = fwrite(ptr, 1, encode_frame_size,  slice_output);
	    	    if (writesize != encode_frame_size) {
	        	    printf("%s %d %d\n", __FUNCTION__, __LINE__, (int)writesize);
	            	//printf("write %d %p %d %p \n", (int)writesize, raw_data, raw_size,output);
	            	//return -1;
	        	}
				fclose(slice_output);
				#endif
				first = 0;
			}
		}



	} else {
//		printf("VLC_RESET %d\n", dut->VLC_RESET);
	}

}
