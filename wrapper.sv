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
	output wire [23:0] AC_BITSTREAM_LEVEL_OUTPUT_ENABLE,
	output wire [23:0] AC_BITSTREAM_LEVEL_SUM,

	output wire [23:0] AC_BITSTREAM_RUN_OUTPUT_ENABLE,
	output wire [23:0] AC_BITSTREAM_RUN_SUM
	
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
	.sum(DC_BITSTREAM_SUM)
);

entropy_encode_ac_level_coefficients entropy_encode_ac_level_coefficients_inst(
	.clk(CLOCK),
	.reset_n(VLC_RESET),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA),
	.output_enable(AC_BITSTREAM_LEVEL_OUTPUT_ENABLE),//mask
	.sum(AC_BITSTREAM_LEVEL_SUM)
);

entropy_encode_ac_run_coefficients entropy_encode_ac_run_coefficients_inst(
	.clk(CLOCK),
	.reset_n(VLC_RESET),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA),
	.output_enable(AC_BITSTREAM_RUN_OUTPUT_ENABLE),//mask
	.sum(AC_BITSTREAM_RUN_SUM)
);


endmodule



