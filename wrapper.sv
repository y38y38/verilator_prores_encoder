`timescale 1ns / 1ps

module wapper(
	input wire CLOCK,
	input wire RESET,

	input wire [31:0] INPUT_DATA[8][8],
	input wire [31:0] QSCALE,
	input wire [31:0] QMAT[8][8],
	
	output wire [31:0] PRE_DCT_OUTPUT[8][8],
	output wire [31:0] DCT_OUTPUT[8][8],

	output wire [31:0] OUTPUT_DATA[8][8],

	input wire VLC_RESET,
	input wire [31:0] INPUT_DC_DATA,
	output wire [31:0] DC_BITSTREAM_OUTPUT_ENABLE,
	output wire [31:0] DC_BITSTREAM_SUM,

	input wire [31:0] INPUT_AC_DATA,
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
output wire [63:0]  set_bit_tmp_bit

    );

//wire [31:0] PRE_DCT_OUTPUT[8][8];


pre_dct pre_dct_inst (
	.CLOCK(CLOCK),
	.RESET(RESET),
	.INPUT_DATA(INPUT_DATA),
	.OUTPUT_DATA(PRE_DCT_OUTPUT)
);


//wire [31:0] DCT_OUTPUT[8][8];

dct dct_inst (
	.CLOCK(CLOCK),
	.RESET(RESET),
	.INPUT_DATA(PRE_DCT_OUTPUT),
	.OUTPUT_DATA(DCT_OUTPUT)
    );


pre_quant_qt_qscale pre_quant_qt_qscale_inst(
	.CLOCK(CLOCK),
	.RESET(RESET),
	.INPUT_DATA(DCT_OUTPUT),
	.QSCALE(QSCALE),
	.QMAT(QMAT),
	.OUTPUT_DATA(OUTPUT_DATA)

);



entropy_encode_dc_coefficients entropy_encode_dc_coefficients_inst(
	.clk(CLOCK),
	.reset_n(VLC_RESET),
	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.DcCoeff(INPUT_DC_DATA),
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
	.reset_n(VLC_RESET),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA),
	.output_enable(AC_BITSTREAM_LEVEL_OUTPUT_ENABLE),//mask
	.sum_n_n(AC_BITSTREAM_LEVEL_SUM),
	.is_expo_golomb_code(l_is_expo_golomb_code),
	.is_expo_golomb_code_n(l_is_expo_golomb_code_n),
	.is_expo_golomb_code_n_n(l_is_expo_golomb_code_n_n),
	.codeword_length_n_n(AC_BITSTREAM_LEVEL_LENGTH)
);

entropy_encode_ac_run_coefficients entropy_encode_ac_run_coefficients_inst(
	.clk(CLOCK),
	.reset_n(VLC_RESET),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA),
	.output_enable(AC_BITSTREAM_RUN_OUTPUT_ENABLE),//mask
//	.sum(AC_BITSTREAM_RUN_SUM),
	.sum_n_n_n(AC_BITSTREAM_RUN_SUM),
	.is_expo_golomb_code(r_is_expo_golomb_code),
	.is_expo_golomb_code_n(r_is_expo_golomb_code_n),
	.is_expo_golomb_code_n_n(r_is_expo_golomb_code_n_n),
	.codeword_length_n_n_n(AC_BITSTREAM_RUN_LENGTH)
);



set_bit set_bit_inst(
	.clock(CLOCK),
	.reset_n(RESET),
	.enable(set_bit_enable),
	.val(set_bit_val),
	.size_of_bit(set_bit_size_of_bit),
	.flush_bit(set_bit_flush_bit),//val, size_of_bitを参照せずに、bitを吐き出す。
	.output_enable_byte(set_bit_output_enable_byte),
	.output_val(set_bit_output_val),

	
	.tmp_buf_bit_offset(set_bit_tmp_buf_bit_offset),
	.tmp_byte(set_bit_tmp_byte),
	 .tmp_bit(set_bit_tmp_bit)
);


endmodule;



