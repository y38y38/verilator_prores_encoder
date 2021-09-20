`timescale 1ns / 1ps

`include "prores_param.v"


module wapper(
	input wire CLOCK,
	input wire RESET,
	input wire [31:0] INPUT_DATA_MEM[4096],
//	input wire [31:0] INPUT_DATA_MEM[64],
	input wire [31:0] INPUT_DATA[64],
	output wire [31:0] INPUT_DATA_ARRAY[8][8],
	output wire [31:0] INPUT_DATA_ARRAY2[8][8],
	input wire [31:0] QSCALE,
	input wire [31:0] Y_QMAT[8][8],
	input wire [31:0] C_QMAT[8][8],
	output wire [31:0] QMAT[8][8],


	output wire [31:0] PRE_DCT_OUTPUT[8][8],
	output wire [31:0] DCT_OUTPUT[8][8],

	output wire [31:0] OUTPUT_DATA[8][8],

	input wire VLC_RESET,
	input wire [31:0] INPUT_DC_DATA,
	output wire [31:0] INPUT_DC_DATA2,
	output wire [31:0] DC_BITSTREAM_OUTPUT_ENABLE,
	output wire [31:0] DC_BITSTREAM_SUM,

	input wire [31:0] INPUT_AC_DATA,
	output  wire [31:0] INPUT_AC_DATA2,
	output wire [31:0] AC_BITSTREAM_LEVEL_LENGTH,
	output wire [31:0] AC_BITSTREAM_LEVEL_OUTPUT_ENABLE,
	output wire [31:0] AC_BITSTREAM_LEVEL_SUM,

	output wire [31:0] AC_BITSTREAM_RUN_OUTPUT_ENABLE,
	output wire [31:0] AC_BITSTREAM_RUN_SUM,
	output wire [31:0] AC_BITSTREAM_RUN_SUM_N,
	output wire [31:0] AC_BITSTREAM_RUN_LENGTH,

output wire [31:0] LENGTH,
output wire [31:0] ABS_PREVIOUSDCDIFF,
output wire [31:0] ABS_PREVIOUSDCDIFF_NEXT,
output wire [31:0] PREVIOUSDCOEFF,
output wire [31:0] PREVIOUSDCDIFF,
output wire [31:0] DC_COEFF_DIFFERENCE,
output wire [31:0] VAL,
output wire [31:0] VAL_N,
output wire [31:0] PPPP,
output wire [1:0] is_expo_golomb_code,
output wire is_add_setbit,
output wire [1:0] r_is_expo_golomb_code_n_n,
output wire [1:0] r_is_expo_golomb_code_n,
output wire [1:0] r_is_expo_golomb_code,
output wire [1:0] l_is_expo_golomb_code_n_n,
output wire [1:0] l_is_expo_golomb_code_n,
output wire [1:0] l_is_expo_golomb_code,
output wire [2:0] k,

input wire [63:0] set_bit_enable,
input wire [63:0] set_bit_val,
input wire [63:0] set_bit_size_of_bit,
input wire [63:0] set_bit_flush_bit,
output wire [3:0]  set_bit_output_enable_byte,
output wire [63:0]  set_bit_output_val,
output wire [63:0]  set_bit_tmp_buf_bit_offset,
output wire [63:0]  set_bit_tmp_byte,
output wire [63:0]  set_bit_tmp_bit,
output wire [31:0] sequence_counter,
output wire [31:0] sequence_counter2,
output wire [31:0] dc_vlc_counter,
output wire [31:0] ac_vlc_counter,
output wire sequence_valid,
output wire dc_vlc_reset,
output wire dc_vlc_output_enable,
output wire ac_vlc_reset,
output wire [31:0] v_data_result[2048],
output wire [31:0] ac_vlc_conefficient1,
output wire [31:0] ac_vlc_block,
output wire [31:0] ac_vlc_position,
output wire dc_output_enable,
output wire [31:0] dc_output_val,
output wire [31:0]  dc_output_size_of_bit,

output wire dc_output_flush,

output wire ac_output_enable,
output wire [63:0] ac_output_val,
output wire [63:0] ac_output_size_of_bit,
output wire ac_vlc_output_flush,
output wire ac_output_flush,
output wire ac_vlc_output_enable,
output wire component_reset_n,

output wire [31:0] slice_sequencer_y_size,
output wire [31:0] slice_sequencer_cb_size,
output wire [31:0] slice_sequencer_counter,
output wire [31:0] slice_sequencer_offset,
output wire [31:0] slice_sequencer_block_num,
output wire [31:0] set_bit_total_byte_size,
output wire is_y,

input wire [31:0] block_num 

    );


slice_sequencer slice_sequencer_inst(
	.clock(CLOCK),
	.reset_n(RESET),
	.set_bit_total_byte_size(set_bit_total_byte_size),
	.component_reset_n(component_reset_n),
	.counter(slice_sequencer_counter),
	.offset(slice_sequencer_offset),
	.block_num(slice_sequencer_block_num),
	.is_y(is_y),
	.y_size(slice_sequencer_y_size),
	.cb_size(slice_sequencer_cb_size)
//	input_mem(INPUT_DATA_MEM),
//	output_mem(slice_sequencer_output_mem)

);



sequencer sequencer_inst(
	.clock(CLOCK),
	.reset_n(component_reset_n),
	.slice_start(component_reset_n),
	.block_num(slice_sequencer_block_num),
 	.sequence_counter(sequence_counter),
	.sequence_valid(sequence_valid),
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
	.counter(sequence_counter),
//	.input_data(INPUT_DATA),
	.input_data(INPUT_DATA_MEM),
	.offset(slice_sequencer_offset),
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
	.INPUT_DATA(INPUT_DATA_ARRAY2),
	.OUTPUT_DATA(PRE_DCT_OUTPUT)
);


//wire [31:0] DCT_OUTPUT[8][8];

dct dct_inst (
	.CLOCK(CLOCK),
	.RESET(component_reset_n),
	.INPUT_DATA(PRE_DCT_OUTPUT),
	.OUTPUT_DATA(DCT_OUTPUT)
    );


pre_quant_qt_qscale pre_quant_qt_qscale_inst(
	.CLOCK(CLOCK),
	.RESET(component_reset_n),
	.INPUT_DATA(DCT_OUTPUT),
	.QSCALE(QSCALE),
	.is_y(is_y),
	.Y_QMAT(Y_QMAT),
	.C_QMAT(C_QMAT),
	.OUTPUT_DATA(OUTPUT_DATA)

);

array_to_mem array_to_mem_inst(
	.clock(CLOCK),
	.reset_n(component_reset_n),
	.counter(sequence_counter2),
	.input_data_array(OUTPUT_DATA),
	.output_data(v_data_result)

);

mem_to_dc_vlc mem_to_dc_vlc_inst(
	.clock(CLOCK),
	.reset_n(component_reset_n),
	.counter(dc_vlc_counter),
	.block_num(slice_sequencer_block_num),
	.input_data(v_data_result),
	.vlc_dc(INPUT_DC_DATA2)
);

mem_to_ac_vlc mem_to_ac_vlc_inst(
	.clock(CLOCK),
	.reset_n(component_reset_n),
	.counter(ac_vlc_counter),
	.block_num(slice_sequencer_block_num),
	.input_data(v_data_result),
	.vlc_ac(INPUT_AC_DATA2),
	.conefficient1(ac_vlc_conefficient1),
	.block(ac_vlc_block),
	.position(ac_vlc_position)

);


entropy_encode_dc_coefficients entropy_encode_dc_coefficients_inst(
	.clk(CLOCK),
	.reset_n(dc_vlc_reset),
	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.DcCoeff(INPUT_DC_DATA2),
	.output_enable(DC_BITSTREAM_OUTPUT_ENABLE),//mask
	.pppp(PPPP),

//	.sum_n(DC_BITSTREAM_SUM),
//	.LENGTH(LENGTH),

	.sum_n_n(DC_BITSTREAM_SUM),
	.codeword_length_n(LENGTH),


	//debug
//	.abs_previousDCDiff(ABS_PREVIOUSDCDIFF),
	.abs_previousDCDiff_next(ABS_PREVIOUSDCDIFF_NEXT), 
	.previousDCCoeff(PREVIOUSDCOEFF), 
	.previousDCDiff(PREVIOUSDCDIFF), 
	.dc_coeff_difference(DC_COEFF_DIFFERENCE), 
	.val(VAL),
	.val_n(VAL_N),
	.is_expo_golomb_code(is_expo_golomb_code),
	.is_add_setbit(is_add_setbit),
	.k(k)
);

entropy_encode_ac_level_coefficients entropy_encode_ac_level_coefficients_inst(
	.clk(CLOCK),
	.reset_n(ac_vlc_reset),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA2),
	.output_enable(AC_BITSTREAM_LEVEL_OUTPUT_ENABLE),//mask
	.sum_n_n(AC_BITSTREAM_LEVEL_SUM),
	.is_expo_golomb_code(l_is_expo_golomb_code),
	.is_expo_golomb_code_n(l_is_expo_golomb_code_n),
	.is_expo_golomb_code_n_n(l_is_expo_golomb_code_n_n),
	.codeword_length_n_n(AC_BITSTREAM_LEVEL_LENGTH)
);

entropy_encode_ac_run_coefficients entropy_encode_ac_run_coefficients_inst(
	.clk(CLOCK),
	.reset_n(ac_vlc_reset),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA2),
	.output_enable(AC_BITSTREAM_RUN_OUTPUT_ENABLE),//mask
//	.sum(AC_BITSTREAM_RUN_SUM),
	.sum_n_n_n(AC_BITSTREAM_RUN_SUM),
	.is_expo_golomb_code(r_is_expo_golomb_code),
	.is_expo_golomb_code_n(r_is_expo_golomb_code_n),
	.is_expo_golomb_code_n_n(r_is_expo_golomb_code_n_n),
	.codeword_length_n_n_n(AC_BITSTREAM_RUN_LENGTH)
);


dc_output dc_output_inst(
	.clock(CLOCK),
	.reset_n(dc_vlc_reset),
	.LENGTH(LENGTH),
	.SUM(DC_BITSTREAM_SUM),
	.enable(dc_vlc_output_enable),
	.output_enable(dc_output_enable),
	.val(dc_output_val),
	.size_of_bit(dc_output_size_of_bit),
	.flush_bit(dc_output_flush)
);


ac_output ac_output_inst(
	.clock(CLOCK),
	.reset_n(ac_vlc_reset),
	.RUN_LENGTH(AC_BITSTREAM_RUN_LENGTH),
	.RUN_SUM(AC_BITSTREAM_RUN_SUM),
	.LEVEL_LENGTH(AC_BITSTREAM_LEVEL_LENGTH),
	.LEVEL_SUM(AC_BITSTREAM_LEVEL_SUM),
	.enable(ac_vlc_output_enable),
	.ac_vlc_output_flush(ac_vlc_output_flush),
	.output_enable(ac_output_enable),
	.val(ac_output_val),
	.size_of_bit(ac_output_size_of_bit),
	.flush_bit(ac_output_flush)
);


wire sb_enable;
wire [63:0] sb_val;
wire [63:0] sb_size_of_bit;
wire sb_flush;
/*
assign sb_enable = set_bit_enable|dc_output_enable;
assign sb_val = set_bit_val|dc_output_val;
assign sb_size_of_bit = set_bit_size_of_bit|dc_output_size_of_bit;
assign sb_flush = set_bit_flush_bit|dc_output_flush;
*/
assign sb_enable = set_bit_enable|dc_output_enable|ac_output_enable;
assign sb_val = set_bit_val|dc_output_val|ac_output_val;
assign sb_size_of_bit = set_bit_size_of_bit|dc_output_size_of_bit|ac_output_size_of_bit;
assign sb_flush = set_bit_flush_bit|dc_output_flush|ac_output_flush;

set_bit set_bit_inst(
	.clock(CLOCK),
	.reset_n(component_reset_n),
	.enable(sb_enable),
	.val(sb_val),
	.size_of_bit(sb_size_of_bit),
	.flush_bit(sb_flush),//val, size_of_bitを参照せずに、bitを吐き出す。
	.output_enable_byte(set_bit_output_enable_byte),
	.output_val(set_bit_output_val),
	.total_byte_size(set_bit_total_byte_size),
	
	.tmp_buf_bit_offset(set_bit_tmp_buf_bit_offset),
	.tmp_byte(set_bit_tmp_byte),
	 .tmp_bit(set_bit_tmp_bit)
);


endmodule;



