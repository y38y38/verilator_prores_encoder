`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2021 11:43:12 PM
// Design Name: 
// Module Name: calc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module dct(
	input CLOCK,
	input RESET,
	input INPUT_DATA_ENABLE,
	input [31:0] INPUT_DATA[8][8],
	output OUTPUT_DATA_ENABLE,
	output [31:0] OUTPUT_DATA[8][8]
    );
logic signed [31:0] s1_output[8][8];
logic s1_butterfly_output_valid[8];
genvar i;
generate
	for(i=0;i<8;i=i+1) begin
		dct_butterfly butterfly1(
			.CLOCK(CLOCK),
			.RESET(RESET),
			.input_valid(INPUT_DATA_ENABLE),
			.DATA(INPUT_DATA[i]),
			.output_valid(s1_butterfly_output_valid[i]),
			.OUT_DATA(s1_output[i])
		);
	end
endgenerate

logic signed [31:0] tmp_data[8][8];

genvar  j,k;
for(j=0;j<8;j++) begin
	for(k=0;k<8;k++) begin
			assign tmp_data[k][j] = s1_output[j][k];
	end
end

logic signed [31:0] s3_output[8][8];
logic s3_butterfly_output_valid[8];


genvar l;
generate
	for(l=0;l<8;l=l+1) begin
		dct_butterfly butterfly2(
			.CLOCK(CLOCK),
			.RESET(RESET),
			.input_valid(s1_butterfly_output_valid[l]),
			.DATA(tmp_data[l]),
			.output_valid(s3_butterfly_output_valid[l]),
			.OUT_DATA(s3_output[l])
		);
	end
endgenerate


assign OUTPUT_DATA_ENABLE = s3_butterfly_output_valid[0];

genvar  o;
for(o=0;o<8;o++) begin
	assign OUTPUT_DATA[o][0] = s3_output[0][o];
	assign OUTPUT_DATA[o][1] = s3_output[1][o];
	assign OUTPUT_DATA[o][2] = s3_output[2][o];
	assign OUTPUT_DATA[o][3] = s3_output[3][o];
	assign OUTPUT_DATA[o][4] = s3_output[4][o];
	assign OUTPUT_DATA[o][5] = s3_output[5][o];
	assign OUTPUT_DATA[o][6] = s3_output[6][o];
	assign OUTPUT_DATA[o][7] = s3_output[7][o];
end
endmodule
