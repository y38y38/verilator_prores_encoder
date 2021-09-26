`timescale 1ns / 1ps

`include "prores_param.v"
`include "encoder_def.v"


module wapper(
	input wire CLOCK,
	input wire RESET,


	//input data
	input wire [31:0] INPUT_DATA_MEM[4096],

	//encode param
	input wire [31:0] QSCALE,
	input wire [31:0] Y_QMAT[8][8],
	input wire [31:0] C_QMAT[8][8],

	//parameter
	input wire [15:0]header_horizontal,
	input wire [15:0]header_vertical,
	input wire [1:0] header_chroma_format,
	input wire [1:0] header_interlace_mode,
	input wire [3:0] header_aspect_ratio_information,
	input wire [3:0] header_frame_rate_code,
	input wire [7:0] header_color_primaries,
	input wire [7:0] header_transfer_characteristic,
	input wire [7:0] header_matrix_coefficients,
	input wire [3:0] header_alpha_channel_type,

	//temporary
	input wire [31:0] slice_size_table_slice_num,
	input wire [31:0] block_num,


	//output
	output wire [3:0]  set_bit_output_enable_byte,
	output wire [63:0]  set_bit_output_val,

	output wire [31:0]	slice_sequencer_offset_addr,
	output wire [31:0]	slice_sequencer_val,
	output wire [31:0]	slice_sequencer_byte_size

    );



wire component_reset_n;
wire [31:0] slice_sequencer_counter;
wire [31:0] slice_sequencer_offset;
wire [31:0] slice_sequencer_block_num;
wire [31:0] set_bit_total_byte_size;
wire is_y;

/*


wire header_output_enable;
wire [63:0] header_val;
wire [63:0] header_size_of_bit;
wire header_flush;

wire matrix_reset_n;
wire matrix_output_enable;
wire [63:0] matrix_val;
wire [63:0] matrix_size_of_bit;
wire matrix_flush;
wire picture_header_output_enable;
wire [63:0] picture_header_val;
wire [63:0] picture_header_size_of_bit;
wire picture_header_flush;
wire slice_size_table_reset_n;
wire slice_size_table_output_enable;
wire [63:0] slice_size_table_val;
wire [63:0] slice_size_table_size_of_bit;
wire slice_size_table_flush;
wire slice_header_output_enable;
wire [63:0] slice_header_val;
wire [63:0] slice_header_size_of_bit;
wire slice_header_flush;
*/

//------------------------------

wire [31:0] sequence_counter;
wire [31:0] sequence_counter2;
wire [31:0] dc_vlc_counter;
wire [31:0] ac_vlc_counter;
wire dc_vlc_reset;
wire dc_vlc_output_enable;
wire ac_vlc_reset;


wire [31:0] INPUT_DATA_ARRAY2[8][8];
wire [31:0] PRE_DCT_OUTPUT[8][8];
wire [31:0] DCT_OUTPUT[8][8];
wire [31:0] OUTPUT_DATA[8][8];
wire [31:0] v_data_result[2048];


wire [31:0] INPUT_DC_DATA2;

wire [31:0] DC_BITSTREAM_SUM;
wire [31:0] LENGTH;


wire [31:0] INPUT_AC_DATA2;

wire [31:0] AC_BITSTREAM_LEVEL_LENGTH;
wire [31:0] AC_BITSTREAM_LEVEL_SUM;

wire [31:0] AC_BITSTREAM_RUN_LENGTH;
wire [31:0] AC_BITSTREAM_RUN_SUM;




wire dc_output_enable;
wire [31:0] dc_output_val;
wire [31:0]  dc_output_size_of_bit;
wire dc_output_flush;
wire ac_output_enable;
wire [63:0] ac_output_val;
wire [63:0] ac_output_size_of_bit;
wire ac_vlc_output_flush;
wire ac_output_flush;
wire ac_vlc_output_enable;




slice_sequencer slice_sequencer_inst(
	.clock(CLOCK),
	.reset_n(RESET),

	//input
	.set_bit_total_byte_size(set_bit_total_byte_size),
	.slice_num(slice_size_table_slice_num),


	.slice_size_table_size(slice_size_table_size),

	.slice_size_offset_addr(slice_size_offset_addr),
	.picture_size_offset_addr(picture_size_offset_addr),
	.frame_size_offset_addr(frame_size_offset_addr),
	.y_size_offset_addr(y_size_offset_addr),
	.cb_size_offset_addr(cb_size_offset_addr),



	//output
	.header2_reset_n(header2_reset_n),

	.header_reset_n(header_reset_n),
	.matrix_reset_n(matrix_reset_n),
	.picture_header_reset_n(picture_header_reset_n),
	.slice_size_table_reset_n(slice_size_table_reset_n),
	.slice_header_reset_n(slice_header_reset_n),
	.component_reset_n(component_reset_n),
	.counter(slice_sequencer_counter),
	.offset(slice_sequencer_offset),
	.block_num(slice_sequencer_block_num),

	.is_y(is_y),
//	.y_size(slice_sequencer_y_size),
//	.cb_size(slice_sequencer_cb_size),

	.offset_addr(slice_sequencer_offset_addr),
	.val(slice_sequencer_val),
	.byte_size(slice_sequencer_byte_size)
	


);



wire [31:0] slice_size_table_size;
wire [31:0] slice_size_offset_addr;
wire [31:0] picture_size_offset_addr;
wire [31:0] frame_size_offset_addr;
wire [31:0] y_size_offset_addr;
wire [31:0] cb_size_offset_addr;

wire header_sb_reset;
wire header_sb_enable;
wire [63:0] header_sb_val;
wire [63:0] header_sb_size_of_bit;
wire header_sb_flush;

header header_inst(
	.clock(CLOCK),
	.reset_n(header2_reset_n),


	//input
	.horizontal(header_horizontal),
	.vertical(header_vertical),
	.chroma_format(header_chroma_format),
	.interlace_mode(header_interlace_mode),
	.aspect_ratio_information(header_aspect_ratio_information),
	.frame_rate_code(header_frame_rate_code),
	.color_primaries(header_color_primaries),
	.transfer_characteristic(header_transfer_characteristic),
	.matrix_coefficients(header_matrix_coefficients),
	.alpha_channel_type(header_alpha_channel_type),
	.Y_QMAT(Y_QMAT),
	.C_QMAT(C_QMAT),
	.QSCALE(QSCALE),

	.slice_size_table_slice_num(slice_size_table_slice_num),

	.set_bit_total_byte_size(set_bit_total_byte_size),

	.sb_reset(header_sb_reset),
	.sb_enable(header_sb_enable),
	.sb_val(header_sb_val),
	.sb_size_of_bit(header_sb_size_of_bit),
	.sb_flush(header_sb_flush),

	.slice_size_table_size(slice_size_table_size),
	.slice_size_offset_addr(slice_size_offset_addr),
	.picture_size_offset_addr(picture_size_offset_addr),
	.frame_size_offset_addr(frame_size_offset_addr),
	.y_size_offset_addr(y_size_offset_addr),
	.cb_size_offset_addr(cb_size_offset_addr)



	//output
//	.output_enable(header_output_enable),
//	.val(header_val),
//	.size_of_bit(header_size_of_bit),
//	.flush_bit(header_flush),
//	.counter(header_counter)

);

/*
frame_header frame_header_inst(
	.clock(CLOCK),
	.reset_n(header_reset_n),


	//input
	.horizontal(header_horizontal),
	.vertical(header_vertical),
	.chroma_format(header_chroma_format),
	.interlace_mode(header_interlace_mode),
	.aspect_ratio_information(header_aspect_ratio_information),
	.frame_rate_code(header_frame_rate_code),
	.color_primaries(header_color_primaries),
	.transfer_characteristic(header_transfer_characteristic),
	.matrix_coefficients(header_matrix_coefficients),
	.alpha_channel_type(header_alpha_channel_type),
	.Y_QMAT(Y_QMAT),
	.C_QMAT(C_QMAT),


	//output
	.output_enable(header_output_enable),
	.val(header_val),
	.size_of_bit(header_size_of_bit),
	.flush_bit(header_flush),
//	.counter(header_counter)

);


matrix matrix_inst (
	.clock(CLOCK),
	.reset_n(matrix_reset_n),

	.Y_QMAT(Y_QMAT),
	.C_QMAT(C_QMAT),
	
	.output_enable(matrix_output_enable),
	.val(matrix_val),
	.size_of_bit(matrix_size_of_bit),
	.flush_bit(matrix_flush),
//	.counter(matrix_counter)

);

picture_header picture_header_inst (
	.clock(CLOCK),
	.reset_n(picture_header_reset_n),

	//output
	.output_enable(picture_header_output_enable),
	.val(picture_header_val),
	.size_of_bit(picture_header_size_of_bit),
	.flush_bit(picture_header_flush),
//	.counter(picture_header_counter)

);


slice_size_table slice_size_table_inst (
	.clock(CLOCK),
	.reset_n(slice_size_table_reset_n),

	//input
	.slice_num(slice_size_table_slice_num),
//	.slice_num(2),


	//output
	.output_enable(slice_size_table_output_enable),
	.val(slice_size_table_val),
	.size_of_bit(slice_size_table_size_of_bit),
	.flush_bit(slice_size_table_flush),
//	.counter(slice_size_table_counter)

);

slice_header slice_header_inst (
	.clock(CLOCK),
	.reset_n(slice_header_reset_n),

	//input
	.qscale(QSCALE),


	//output
	.output_enable(slice_header_output_enable),
	.val(slice_header_val),
	.size_of_bit(slice_header_size_of_bit),
	.flush_bit(slice_header_flush),
//	.counter(slice_header_counter)

);

*/

sequencer sequencer_inst(
	.clock(CLOCK),
	.reset_n(component_reset_n),

	//input
	.slice_start(component_reset_n),
	.block_num(slice_sequencer_block_num),
 	.sequence_counter(sequence_counter),
//	.sequence_valid(sequence_valid),


	//output
	.dc_vlc_reset(dc_vlc_reset),
	.dc_vlc_output_enable(dc_vlc_output_enable),
	.dc_vlc_counter(dc_vlc_counter),
	.ac_vlc_reset(ac_vlc_reset),
	.ac_vlc_output_enable(ac_vlc_output_enable),
	.ac_vlc_output_flush(ac_vlc_output_flush),
	.ac_vlc_counter(ac_vlc_counter),
	.sequence_counter2(sequence_counter2)

);
//wire [31:0] PRE_DCT_OUTPUT[8][8];

array_from_mem array_form_mem_inst (
	.clock(CLOCK),
	.reset_n(component_reset_n),

	//input
	.counter(sequence_counter),
	.input_data(INPUT_DATA_MEM),
	.offset(slice_sequencer_offset),


	//output
	.output_data_array(INPUT_DATA_ARRAY2)
);
/*
array array_inst (
	.input_data(INPUT_DATA),
	.output_array_data(INPUT_DATA_ARRAY)
);
*/

pre_dct pre_dct_inst (
	.CLOCK(CLOCK),
	.RESET(component_reset_n),

	//input
	.INPUT_DATA(INPUT_DATA_ARRAY2),

	//output
	.OUTPUT_DATA(PRE_DCT_OUTPUT)
);


//wire [31:0] DCT_OUTPUT[8][8];

dct dct_inst (
	.CLOCK(CLOCK),
	.RESET(component_reset_n),

	//input
	.INPUT_DATA(PRE_DCT_OUTPUT),

	//output
	.OUTPUT_DATA(DCT_OUTPUT)
    );


pre_quant_qt_qscale pre_quant_qt_qscale_inst(
	.CLOCK(CLOCK),
	.RESET(component_reset_n),

	//input
	.INPUT_DATA(DCT_OUTPUT),
	.QSCALE(QSCALE),
	.is_y(is_y),
	.Y_QMAT(Y_QMAT),
	.C_QMAT(C_QMAT),

	//output
	.OUTPUT_DATA(OUTPUT_DATA)

);

array_to_mem array_to_mem_inst(
	.clock(CLOCK),
	.reset_n(component_reset_n),

	//input
	.counter(sequence_counter2),
	.input_data_array(OUTPUT_DATA),
	
	//output
	.output_data(v_data_result)

);

mem_to_dc_vlc mem_to_dc_vlc_inst(
	.clock(CLOCK),
	.reset_n(component_reset_n),
	.counter(dc_vlc_counter),

	//input
	.block_num(slice_sequencer_block_num),
	.input_data(v_data_result),

	//output
	.vlc_dc(INPUT_DC_DATA2)
);

mem_to_ac_vlc mem_to_ac_vlc_inst(
	.clock(CLOCK),
	.reset_n(component_reset_n),

	//input
	.counter(ac_vlc_counter),
	.block_num(slice_sequencer_block_num),
	.input_data(v_data_result),

	//output
	.vlc_ac(INPUT_AC_DATA2),
	//.conefficient1(ac_vlc_conefficient1),
	//.block(ac_vlc_block),
	//.position(ac_vlc_position)

);


entropy_encode_dc_coefficients entropy_encode_dc_coefficients_inst(
	.clk(CLOCK),
	.reset_n(dc_vlc_reset),
	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.DcCoeff(INPUT_DC_DATA2),
//	.output_enable(DC_BITSTREAM_OUTPUT_ENABLE),//mask
//	.pppp(PPPP),

//	.sum_n(DC_BITSTREAM_SUM),
//	.LENGTH(LENGTH),

	.sum_n_n(DC_BITSTREAM_SUM),
	.codeword_length_n(LENGTH),


	//debug
//	.abs_previousDCDiff(ABS_PREVIOUSDCDIFF),
//	.abs_previousDCDiff_next(ABS_PREVIOUSDCDIFF_NEXT), 
//	.previousDCCoeff(PREVIOUSDCOEFF), 
//	.previousDCDiff(PREVIOUSDCDIFF), 
//	.dc_coeff_difference(DC_COEFF_DIFFERENCE), 
//	.val(VAL),
//	.val_n(VAL_N),
//	.is_expo_golomb_code(is_expo_golomb_code),
//	.is_add_setbit(is_add_setbit),
//	.k(k)
);

entropy_encode_ac_level_coefficients entropy_encode_ac_level_coefficients_inst(
	.clk(CLOCK),
	.reset_n(ac_vlc_reset),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA2),
//	.output_enable(AC_BITSTREAM_LEVEL_OUTPUT_ENABLE),//mask
	.sum_n_n(AC_BITSTREAM_LEVEL_SUM),
//	.is_expo_golomb_code(l_is_expo_golomb_code),
//	.is_expo_golomb_code_n(l_is_expo_golomb_code_n),
//	.is_expo_golomb_code_n_n(l_is_expo_golomb_code_n_n),
	.codeword_length_n_n(AC_BITSTREAM_LEVEL_LENGTH)
);

entropy_encode_ac_run_coefficients entropy_encode_ac_run_coefficients_inst(
	.clk(CLOCK),
	.reset_n(ac_vlc_reset),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA2),
//	.output_enable(AC_BITSTREAM_RUN_OUTPUT_ENABLE),//mask
//	.sum(AC_BITSTREAM_RUN_SUM),
	.sum_n_n_n(AC_BITSTREAM_RUN_SUM),
//	.is_expo_golomb_code(r_is_expo_golomb_code),
//	.is_expo_golomb_code_n(r_is_expo_golomb_code_n),
//	.is_expo_golomb_code_n_n(r_is_expo_golomb_code_n_n),
	.codeword_length_n_n_n(AC_BITSTREAM_RUN_LENGTH)
);


dc_output dc_output_inst(
	.clock(CLOCK),
	.reset_n(dc_vlc_reset),

	//input
	.LENGTH(LENGTH),
	.SUM(DC_BITSTREAM_SUM),
	.enable(dc_vlc_output_enable),

	//output
	.output_enable(dc_output_enable),
	.val(dc_output_val),
	.size_of_bit(dc_output_size_of_bit),
	.flush_bit(dc_output_flush)
);


ac_output ac_output_inst(
	.clock(CLOCK),
	.reset_n(ac_vlc_reset),
	

	//input
	.RUN_LENGTH(AC_BITSTREAM_RUN_LENGTH),
	.RUN_SUM(AC_BITSTREAM_RUN_SUM),
	.LEVEL_LENGTH(AC_BITSTREAM_LEVEL_LENGTH),
	.LEVEL_SUM(AC_BITSTREAM_LEVEL_SUM),
	.enable(ac_vlc_output_enable),
	.ac_vlc_output_flush(ac_vlc_output_flush),

	//output
	.output_enable(ac_output_enable),
	.val(ac_output_val),
	.size_of_bit(ac_output_size_of_bit),
	.flush_bit(ac_output_flush)
);



/*
assign sb_enable = set_bit_enable|dc_output_enable|ac_output_enable;
assign sb_val = set_bit_val|dc_output_val|ac_output_val;
assign sb_size_of_bit = set_bit_size_of_bit|dc_output_size_of_bit|ac_output_size_of_bit;
assign sb_flush = set_bit_flush_bit|dc_output_flush|ac_output_flush;
*/



wire sb_reset;
wire sb_enable;
wire [63:0] sb_val;
wire [63:0] sb_size_of_bit;
wire sb_flush;

assign sb_reset = component_reset_n 
				//	| picture_header_reset_n
				//	|matrix_reset_n
				//	|header_reset_n
				//	|slice_size_table_reset_n
				//	|slice_header_reset_n
					|header2_reset_n;

assign sb_enable = dc_output_enable
					|ac_output_enable
				//	|header_output_enable
				//	|matrix_output_enable
				//	|picture_header_output_enable
				//	|slice_size_table_output_enable
				//	|slice_header_output_enable
					|header_sb_enable;

assign sb_val = dc_output_val
					|ac_output_val
				//	|header_val
				//	|matrix_val
				//	|picture_header_val
				//	|slice_size_table_val
				//	|slice_header_val
					|header_sb_val;




assign sb_size_of_bit = dc_output_size_of_bit
						|ac_output_size_of_bit
				//		|header_size_of_bit
				//		|matrix_size_of_bit
				//		|picture_header_size_of_bit
				//		|slice_size_table_size_of_bit
				//		|slice_header_size_of_bit
						|header_sb_size_of_bit;

assign sb_flush = dc_output_flush
						|ac_output_flush
				//		|header_flush
				//		|matrix_flush
				//		|picture_header_flush
				//		|slice_size_table_flush
				//		|slice_header_flush
						|header_sb_flush;


set_bit set_bit_inst(
	.clock(CLOCK),
	.reset_n(sb_reset),

	//input
	.enable(sb_enable),
	.val(sb_val),
	.size_of_bit(sb_size_of_bit),
	.flush_bit(sb_flush),//val, size_of_bitを参照せずに、bitを吐き出す。

	//output
	.output_enable_byte(set_bit_output_enable_byte),
	.output_val(set_bit_output_val),
	.total_byte_size(set_bit_total_byte_size),
	
//	.tmp_buf_bit_offset(set_bit_tmp_buf_bit_offset),
//	.tmp_byte(set_bit_tmp_byte),
//	 .tmp_bit(set_bit_tmp_bit)
);


endmodule;



