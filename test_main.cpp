#include <iostream>
#include <verilated.h>
//#include <verilated_fst_c.h> 
#include "Vwrapper.h"
#include "test_utility.h"
#include <math.h>

#include "encode_component.h"


#include "config.h"
#include "dct.h"
#include "bitstream.h"
#include "vlc.h"
#include "slice.h"

#include "encoder_main.h"

extern int16_t v_y_data[128*16*2];
extern int16_t v_cb_data[128*16];
extern int16_t v_cr_data[128*16];

extern FILE *slice_output;


int encoder_main(int argc, char **argv);

int main(int argc, char** argv) {
	
	Verilated::commandArgs(argc, argv);

	encoder_main(argc, argv);

	int ret = init_param(argc, argv);
	if (ret <0) {
		return -1;
	}

	struct bitstream bitstream;
	bitstream.bitstream_buffer  = (uint8_t*)malloc(MAX_SLICE_BITSTREAM_SIZE);
	if (bitstream.bitstream_buffer == NULL) {
		printf("error %s %d\n", __FILE__, __LINE__);
		return 0;
	}

	int16_t *component_data[3];
	component_data[0] = v_y_data;
	component_data[1] = v_cb_data;
	component_data[2] = v_cr_data;

	uint8_t  *component_matrix_table[3];
	component_matrix_table[0] = luma_matrix2_;
	component_matrix_table[1] = chroma_matrix2_;
	component_matrix_table[2] = chroma_matrix2_;

	int block_num[3];
	block_num[0] = 32;
	block_num[1] = 16;
	block_num[2] = 16;

	uint16_t component_size[3];
	initBitStream(&bitstream);
	encode_slice_component_v(component_data[0],
								 component_data[1],
								 component_data[2],
								 component_matrix_table[0], 
								 component_matrix_table[1], 
								 qscale_table_[0], block_num[0], &bitstream);

	
	uint32_t encode_frame_size;
	uint8_t *ptr = getBitStream(&bitstream, &encode_frame_size);
    size_t writesize = fwrite(ptr, 1, encode_frame_size,  slice_output);
    if (writesize != encode_frame_size) {
	    printf("%s %d %d\n", __FUNCTION__, __LINE__, (int)writesize);
    	//return -1;
	}
	fclose(slice_output);

}