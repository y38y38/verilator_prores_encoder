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


static int time_counter = 0;
int encoder_main(int argc, char **argv);

int main(int argc, char** argv) {
	
	Verilated::commandArgs(argc, argv);

#if 1
	encoder_main(argc, argv);
	//printf("encode end\n");
//	return 0;
#endif

	int ret = init_param(argc, argv);
	if (ret <0) {
		return -1;
	}

	// Instantiate DUT
	Vwrapper *dut = new Vwrapper();
	// Trace DUMP ON
//	Verilated::traceEverOn(true);
//	VerilatedFstC* tfp = new VerilatedFstC;

//	dut->trace(tfp, 100);  // Trace 100 levels of hierarchy
//	tfp->open("simx.fst");
#if 0
	// Format
	init_test(dut);

	reset_test(dut);

	// Reset Time
	while (time_counter < 10) {
		toggle_clock(dut);
//		tfp->dump(time_counter);
		time_counter++;
	}
	// Release reset
	unreset_test(dut);
	//printf("loop\n");
	while (is_run(time_counter) && !Verilated::gotFinish()) {
//			printf("2 DcCoeff %d\n", dut->INPUT_DC_DATA);
//			printf("2 previousDCCoeff %d\n", dut->PREVIOUSDCOEFF);
		toggle_clock(dut);
//			printf("3 DcCoeff %d\n", dut->INPUT_DC_DATA);
//			printf("3 previousDCCoeff %d\n", dut->PREVIOUSDCOEFF);
		if (dut->CLOCK) {
//			printf("4 DcCoeff %d\n", dut->INPUT_DC_DATA);
//			printf("4 previousDCCoeff %d\n", dut->PREVIOUSDCOEFF);
			posedge_clock(dut);
		}
//			printf("5 DcCoeff %d\n", dut->INPUT_DC_DATA);
//			printf("5 previousDCCoeff %d\n", dut->PREVIOUSDCOEFF);
		// Evaluate DUT
		//printf("b dc_coeff %d\n", dut->INPUT_DC_DATA);
		dut->eval();
		//printf("a dc_coeff %d\n", dut->INPUT_DC_DATA);
		if (dut->CLOCK) {
//		printf("1 DcCoeff %d\n", dut->INPUT_DC_DATA);
//		printf("1 previousDCCoeff %d\n", dut->PREVIOUSDCOEFF);
			posedge_clock_result(dut);
		}
//		tfp->dump(time_counter);  // 波形ダンプ用の記述を追加
		time_counter++;
//return 0;
	}
//return 0;
	end_test(dut);
	dut->final();
//	tfp->close(); 
#else
	struct bitstream bitstream[3];
				//printf("a %d \n", getBitSize(&write_bitstream));

	for(int i=0;i<3;i++) {
		bitstream[i].bitstream_buffer  = (uint8_t*)malloc(MAX_SLICE_BITSTREAM_SIZE);
		if (bitstream[i].bitstream_buffer == NULL) {
			printf("error %s %d\n", __FILE__, __LINE__);
			return 0;
		}
		initBitStream(&bitstream[i]);
	}
//	struct Slice slice_param;
//	slice_param = slice_param[0];
	uint16_t y_size = 0;
	uint16_t cb_size = 0;
	uint16_t cr_size = 0;


		//uint32_t size  = getBitSize(&bitstream[0]);
		//printf("y size=%d\n", size/8);

//	for(int i=0;i<3;i++) {
		encode_slice_component_v(v_y_data,luma_matrix2_, qscale_table_[0], 32, &bitstream[0]);

		//end of y 
		uint32_t size  = getBitSize(&bitstream[0]);
		if (size & 7 )  {
			setBit(&bitstream[0], 0x0, 8 - (size % 8));
		}
		//printf("y size=%d\n", size/8);

	    uint32_t current_offset = getBitSize(&bitstream[0]);
		//printf("y size=%d\n", current_offset/8);
		uint32_t vlc_size = (current_offset)/8;
	    y_size  = SET_DATA16(vlc_size);
		//printf("y_size=%d\n", y_size);

   		//current_offset = getBitSize(slice_param[0].bitstream);
		//printf("offset %d\n", current_offset/8);

		size  = getBitSize(&bitstream[0]);

		setByte(slice_param[0].bitstream, bitstream[0].bitstream_buffer, size/8);
	
		//printf("y_size %d\n", y_size);
   		current_offset = getBitSize(slice_param[0].bitstream);
		//printf("offset %d\n", current_offset/8);



		encode_slice_component_v(v_cb_data,chroma_matrix2_, qscale_table_[0], 16, &bitstream[1]);
		//end of y 
		size  = getBitSize(&bitstream[1]);
		if (size & 7 )  {
		setBit(&bitstream[1], 0x0, 8 - (size % 8));
		}
		//printf("cb size=%d\n", size);
	    current_offset = getBitSize(&bitstream[1]);
		vlc_size = (current_offset)/8;
	    cb_size  = SET_DATA16(vlc_size);

		//printf("%d \n", getBitSize(slice_param[0].bitstream));
		setByte(slice_param[0].bitstream, bitstream[1].bitstream_buffer, vlc_size);
		//printf("%x\n", bitstream[1].bitstream_buffer[0]);

		encode_slice_component_v(v_cr_data,chroma_matrix2_, qscale_table_[0], 16, &bitstream[2]);


				//end of cr
				size  = getBitSize(&bitstream[2]);
				if (size & 7 )  {
	       			setBit(&bitstream[2], 0x0, 8 - (size % 8));
	   			}
		//printf("cr size=%d\n", size);
	    current_offset = getBitSize(&bitstream[2]);
		vlc_size = (current_offset)/8;
	    cr_size  = SET_DATA16(vlc_size);



   		current_offset = getBitSize(slice_param[0].bitstream);
		//printf("offset %d\n", current_offset/8);
		setByte(slice_param[0].bitstream, bitstream[2].bitstream_buffer, vlc_size);
   		current_offset = getBitSize(slice_param[0].bitstream);
		//printf("offset %d\n", current_offset/8);
		
			    setByteInOffset(slice_param[0].bitstream, code_size_of_y_data_offset , (uint8_t *)&y_size, 2);
	    		setByteInOffset(slice_param[0].bitstream, code_size_of_cb_data_offset , (uint8_t *)&cb_size, 2);
	    		current_offset = getBitSize(slice_param[0].bitstream);
				//printf("size=0x%x\n",  ((current_offset - slice_start_offset)/8));
	    		uint32_t slice_size =  ((current_offset - slice_start_offset)/8);
				write_slice_size(slice_param[0].slice_no, slice_size);

				//printf("a %d \n", getBitSize(&write_bitstream));

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

	//	FILE *aa = fopen("./tmp/out.bin", "w");
		//	printf("encode_frame_size %d %p %p\n", encode_frame_size,ptr , slice_output);
//		        size_t writesize = fwrite(ptr, 1, encode_frame_size,  aa);
		        size_t writesize = fwrite(ptr, 1, encode_frame_size,  slice_output);
	    	    if (writesize != encode_frame_size) {
	        	    printf("%s %d %d\n", __FUNCTION__, __LINE__, (int)writesize);
	            	//printf("write %d %p %d %p \n", (int)writesize, raw_data, raw_size,output);
	            	//return -1;
	        	}
		//		printf("writesize %d\n", writesize);
				fclose(slice_output);
				//fclose(aa);

//	}
#endif
}