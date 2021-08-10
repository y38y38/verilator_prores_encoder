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
	input wire [19:0] INPUT_DC_DATA,
	output wire [23:0] DC_BITSTREAM_OUTPUT_ENABLE,
	output wire [23:0] DC_BITSTREAM_SUM,

	input wire [19:0] INPUT_AC_DATA,
	output wire [31:0] AC_BITSTREAM_LEVEL_LENGTH,
	output wire [23:0] AC_BITSTREAM_LEVEL_OUTPUT_ENABLE,
	output wire [23:0] AC_BITSTREAM_LEVEL_SUM,

	output wire [23:0] AC_BITSTREAM_RUN_OUTPUT_ENABLE,
	output wire [23:0] AC_BITSTREAM_RUN_SUM,
	output wire [31:0] AC_BITSTREAM_RUN_LENGTH,

output wire [23:0] LENGTH,
output wire [19:0] ABS_PREVIOUSDCDIFF,
output wire [19:0] ABS_PREVIOUSDCDIFF_NEXT,
output wire [19:0] PREVIOUSDCOEFF,
output wire [19:0] PREVIOUSDCDIFF,
output wire [19:0] DC_COEFF_DIFFERENCE,
output wire [19:0] VAL,
output wire [19:0] VAL_N,
output wire [23:0] PPPP,
output wire [1:0] is_expo_golomb_code,
output wire is_add_setbit,
output wire [2:0] k

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
	.sum(DC_BITSTREAM_SUM),
	.pppp(PPPP),

	//debug
	.LENGTH(LENGTH),
	.abs_previousDCDiff(ABS_PREVIOUSDCDIFF),
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
	.sum(AC_BITSTREAM_LEVEL_SUM),
	.codeword_length(AC_BITSTREAM_LEVEL_LENGTH)
);

entropy_encode_ac_run_coefficients entropy_encode_ac_run_coefficients_inst(
	.clk(CLOCK),
	.reset_n(VLC_RESET),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA),
	.output_enable(AC_BITSTREAM_RUN_OUTPUT_ENABLE),//mask
	.sum(AC_BITSTREAM_RUN_SUM),
	.codeword_length(AC_BITSTREAM_RUN_LENGTH)
);


endmodule



