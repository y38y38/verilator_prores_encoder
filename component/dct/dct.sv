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

	output reg OUTPUT_DATA_ENABLE,
	output reg [31:0] OUTPUT_DATA[8][8]
    );
//	reg [31:0] OUTPUT_DATA[8][8];

	reg [31:0] counter;
	always@(posedge CLOCK) begin
		if (!RESET) begin
			counter <= 32'h0;
		end else begin
			if (INPUT_DATA_ENABLE) begin
				counter <= counter + 32'h1;
			end
		end
	end
logic signed [31:0] s1_output[8][8];
logic s1_butterfly_output_valid[8];

`ifdef TEST3
		dct_butterfly butterfly1(
			.CLOCK(CLOCK),
			.RESET(RESET),
			.input_valid(1),
			.DATA(INPUT_DATA[counter%8]),
			.output_valid(s1_butterfly_output_valid[counter%8]),
			.OUT_DATA(s1_output[counter%8])
		);
`else
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

`endif



logic signed [31:0] tmp_data[8][8];

genvar  j,k;
for(j=0;j<8;j++) begin
	for(k=0;k<8;k++) begin
			assign tmp_data[k][j] = s1_output[j][k];
	end
end


	reg [31:0] counter2;
	always@(posedge CLOCK) begin
		if (!RESET) begin
			counter2 <= 32'h0;
		end else begin
			//$display("%d %d", counter2, OUTPUT_DATA[0][0]);
			if (s1_butterfly_output_valid[0]) begin
				counter2 <= counter2 + 32'h1;
`ifdef LOG
`ifdef TEST4
				$display("%d %d %d %d %d %d %d %d %d %d", counter2, tmp_data[counter2%8][0],tmp_data[counter2%8][1],tmp_data[counter2%8][2],tmp_data[counter2%8][3],tmp_data[counter2%8][4],tmp_data[counter2%8][5],tmp_data[counter2%8][6],tmp_data[counter2%8][7], s3_output[0][0]);
//				$display("%d %d %d %d %d %d %d %d %d %d", counter2, s1_butterfly_output_valid[counter2%8],s1_butterfly_output_valid[counter2%8],s1_butterfly_output_valid[counter2%8],s1_butterfly_output_valid[counter2%8],s1_butterfly_output_valid[counter2%8],s1_butterfly_output_valid[counter2%8],s1_butterfly_output_valid[counter2%8],s1_butterfly_output_valid[counter2%8], s3_output[0][0]);
				$display("s1 %d %d %d %d %d %d %d %d",butterfly2.s1[0],butterfly2.s1[1],butterfly2.s1[2],butterfly2.s1[3],butterfly2.s1[4],butterfly2.s1[5],butterfly2.s1[6],butterfly2.s1[7]);
				$display("s2 %d %d %d %d %d %d %d %d",butterfly2.s2[0],butterfly2.s2[1],butterfly2.s2[2],butterfly2.s2[3],butterfly2.s2[4],butterfly2.s2[5],butterfly2.s2[6],butterfly2.s2[7]);
				$display("s3 %d %d %d %d %d %d %d %d",butterfly2.s3[0],butterfly2.s3[1],butterfly2.s3[2],butterfly2.s3[3],butterfly2.s3[4],butterfly2.s3[5],butterfly2.s3[6],butterfly2.s3[7]);
				$display("s4 %d %d %d %d %d %d %d %d",butterfly2.s4[0],butterfly2.s4[1],butterfly2.s4[2],butterfly2.s4[3],butterfly2.s4[4],butterfly2.s4[5],butterfly2.s4[6],butterfly2.s4[7]);
				$display("s5 %d %d %d %d %d %d %d %d",butterfly2.s5[0],butterfly2.s5[1],butterfly2.s5[2],butterfly2.s5[3],butterfly2.s5[4],butterfly2.s5[5],butterfly2.s5[6],butterfly2.s5[7]);
`else
				$display("%d %d %d %d %d %d %d %d %d %d", counter2, tmp_data[0][0],tmp_data[0][1],tmp_data[0][2],tmp_data[0][3],tmp_data[0][4],tmp_data[0][5],tmp_data[0][6],tmp_data[0][7], s3_output[0][0]);
//				$display("%d %d %d %d %d %d %d %d %d %d", counter2, s1_butterfly_output_valid[0],s1_butterfly_output_valid[1],s1_butterfly_output_valid[2],s1_butterfly_output_valid[3],s1_butterfly_output_valid[4],s1_butterfly_output_valid[5],s1_butterfly_output_valid[6],s1_butterfly_output_valid[7], s3_output[0][0]);
				$display("s1 %d %d %d %d %d %d %d %d",butterfly20.s1[0],butterfly20.s1[1],butterfly20.s1[2],butterfly20.s1[3],butterfly20.s1[4],butterfly20.s1[5],butterfly20.s1[6],butterfly20.s1[7]);
				$display("s2 %d %d %d %d %d %d %d %d",butterfly20.s2[0],butterfly20.s2[1],butterfly20.s2[2],butterfly20.s2[3],butterfly20.s2[4],butterfly20.s2[5],butterfly20.s2[6],butterfly20.s2[7]);
				$display("s3 %d %d %d %d %d %d %d %d",butterfly20.s3[0],butterfly20.s3[1],butterfly20.s3[2],butterfly20.s3[3],butterfly20.s3[4],butterfly20.s3[5],butterfly20.s3[6],butterfly20.s3[7]);
				$display("s4 %d %d %d %d %d %d %d %d",butterfly20.s4[0],butterfly20.s4[1],butterfly20.s4[2],butterfly20.s4[3],butterfly20.s4[4],butterfly20.s4[5],butterfly20.s4[6],butterfly20.s4[7]);
				$display("s5 %d %d %d %d %d %d %d %d",butterfly20.s5[0],butterfly20.s5[1],butterfly20.s5[2],butterfly20.s5[3],butterfly20.s5[4],butterfly20.s5[5],butterfly20.s5[6],butterfly20.s5[7]);
`endif 
`else
`endif
			end
		end
	end


wire signed [31:0] s3_output[8][8];
logic s3_butterfly_output_valid[8];

`ifdef TEST4
	dct_butterfly butterfly2(
		.CLOCK(CLOCK),
		.RESET(RESET),
		.input_valid(s1_butterfly_output_valid[counter2%8]),
		.DATA(tmp_data[counter2%8]),
		.output_valid(s3_butterfly_output_valid[counter2%8]),
//		.OUT_DATA(s3_output[(counter2+4)%8])
		.OUT_DATA(s3_output[0])
	);
`else
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
`endif






genvar  o;
generate
for(o=0;o<8;o++) begin
	always@(posedge CLOCK) begin
		if (!RESET) begin
			OUTPUT_DATA[o][0] <= 32'h0;
			OUTPUT_DATA[o][1] <= 32'h0;
			OUTPUT_DATA[o][2] <= 32'h0;
			OUTPUT_DATA[o][3] <= 32'h0;
			OUTPUT_DATA[o][4] <= 32'h0;
			OUTPUT_DATA[o][5] <= 32'h0;
			OUTPUT_DATA[o][6] <= 32'h0;
			OUTPUT_DATA[o][7] <= 32'h0;
			OUTPUT_DATA_ENABLE <= 1'b0;
		end else begin
			OUTPUT_DATA[o][0] <= s3_output[0][o];
			OUTPUT_DATA[o][1] <= s3_output[1][o];
			OUTPUT_DATA[o][2] <= s3_output[2][o];
			OUTPUT_DATA[o][3] <= s3_output[3][o];
			OUTPUT_DATA[o][4] <= s3_output[4][o];
			OUTPUT_DATA[o][5] <= s3_output[5][o];
			OUTPUT_DATA[o][6] <= s3_output[6][o];
			OUTPUT_DATA[o][7] <= s3_output[7][o];
			OUTPUT_DATA_ENABLE <= s3_butterfly_output_valid[0];
		end
	end
end
endgenerate


endmodule
