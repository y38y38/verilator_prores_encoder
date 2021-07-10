#include <stdio.h>
#include <stdlib.h>
#include "encoder_main.h"
#include "test_utility.h"

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

void posedge_clock_result(Vwrapper *dut){
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
			if (result_block_counter>=0 && result_block_counter<32) {
			//printf("%d %d\n", first,result_block_counter );
//				memcpy(&v_y_data_result[result_y_block_counter*64], dut->DCT_OUTPUT, 64*2);
//				printf("%d %d\n", dut->DCT_OUTPUT[0][0], dut->DCT_OUTPUT[0][1] );
				for(int i=0;i<8;i++) {
					for(int j=0;j<8;j++) {
						v_y_data_result[(result_y_block_counter*64) + (i*8) + j] = dut->OUTPUT_DATA[i][j];
						printf("%d ", v_y_data_result[(i*8) + j + (result_y_block_counter*64)]);
					}
				}
				printf("\n");
				result_y_block_counter++;
			} else if (result_block_counter >= 32 && result_block_counter < 48) {
			//printf("%d %d\n", first,result_block_counter );
//				memcpy(&v_cb_data_result[result_cb_block_counter*64], dut->OUTPUT_DATA, 64*2);
				for(int i=0;i<8;i++) {
					for(int j=0;j<8;j++) {
						v_cb_data_result[(result_cb_block_counter*64) + (i*8) + j] = dut->OUTPUT_DATA[i][j];
						printf("%d ", v_cb_data_result[(i*8)+ j + (result_cb_block_counter*64)]);
					}
				}
				printf("\n");
				result_cb_block_counter++;
			} else if (result_block_counter >= 48 && result_block_counter < 64) {
			//printf("%d %d\n", first,result_block_counter );
//				memcpy(&v_cr_data_result[result_cr_block_counter*64], dut->OUTPUT_DATA, 64*2);
				for(int i=0;i<8;i++) {
					for(int j=0;j<8;j++) {
						v_cr_data_result[(result_cr_block_counter*64) + (i*8) + j] = dut->OUTPUT_DATA[i][j];
						printf("%d ", v_cr_data_result[(i*8)+ j + (result_cr_block_counter*64)]);
					}
				}
				printf("\n");
				result_cr_block_counter++;
			} else {
//				printf("end of dct %d %d %d %d %d\n", first , result_block_counter, result_y_block_counter, result_cb_block_counter, result_cr_block_counter);
			}
			result_block_counter++;
//			printf("result_block_counter %d\n",result_block_counter );
		}
}
static int block_counter = 0;
static int block_cb_counter = 0;
static int block_cr_counter = 0;
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
		block_counter = 0;
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
}

bool is_run(int time_counter) {
//	printf("is %d\n", time_counter);
	if (time_counter < 200) {
		return true;

	} else {
		return false;
	}
}

void init_test(Vwrapper *dut) {
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
	dut->eval();

}
