`timescale 1ns / 1ps

module wapper(
	input CLOCK,
	input RESET,
	input INPUT_DATA_ENABLE,
	input [31:0] INPUT_DATA[8][8],
	output OUTPUT_DATA_ENABLE,
	output [31:0] OUTPUT_DATA[8][8]
    );


dct dct_inst (
	.CLOCK(CLOCK),
	.RESET(RESET),
	.INPUT_DATA_ENABLE(INPUT_DATA_ENABLE),
	.INPUT_DATA(INPUT_DATA),
	.OUTPUT_DATA_ENABLE(OUTPUT_DATA_ENABLE),
	.OUTPUT_DATA(OUTPUT_DATA)
    );

endmodule



