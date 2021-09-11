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

	for(int i=0;i<3;i++) {
		initBitStream(&bitstream);
		encode_slice_component_v(component_data[i],component_matrix_table[i], qscale_table_[0], block_num[i], &bitstream);

		uint32_t size  = getBitSize(&bitstream);
		if (size & 7 )  {
			setBit(&bitstream, 0x0, 8 - (size % 8));
		}

	    uint32_t current_offset = getBitSize(&bitstream);
		uint32_t vlc_size = (current_offset)/8;
	    component_size[i]  = SET_DATA16(vlc_size);
		//printf("vlc %d\n",vlc_size);
		setByte(slice_param[0].bitstream, bitstream.bitstream_buffer, vlc_size);

	}

    setByteInOffset(slice_param[0].bitstream, code_size_of_y_data_offset , (uint8_t *)&component_size[0], 2);
	setByteInOffset(slice_param[0].bitstream, code_size_of_cb_data_offset , (uint8_t *)&component_size[1], 2);
	uint32_t current_offset = getBitSize(slice_param[0].bitstream);
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
    	//return -1;
	}
	fclose(slice_output);

}