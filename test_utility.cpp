#include <stdio.h>
#include <stdlib.h>

#include "test_utility.h"


#define MAX_X   (8)
#define MAX_Y   (8)
int org[MAX_X * MAX_Y];

FILE *in = NULL;
FILE *out = NULL;
int width = 0;
int height = 0;


extern int v_y_data[128*16*2];
extern int v_cb_data[128*16];
extern int v_cr_data[128*16];


void posedge_clock_result(Vwrapper *dut){
	if (dut->OUTPUT_DATA_ENABLE != 0) {
		static int first = 1;
		if (first) {
			int i,j;
			for(i=0;i<8;i++) {
				for(j=0;j<8;j++) {
					fprintf(out, "%d\n", dut->OUTPUT_DATA[i][j]);
				}
			}
			first = 0;
		}
	}
}

void posedge_clock(Vwrapper *dut){
	int i,j;
	for(i=0;i<8;i++) {
		for(j=0;j<8;j++) {
			dut->INPUT_DATA[i][j] = v_y_data[(i*8)+j];
			}
	}
	dut->INPUT_DATA_ENABLE=1;
}


void init_test(Vwrapper *dut) {
}

void end_test(Vwrapper *dut) {
	fclose(out);
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
