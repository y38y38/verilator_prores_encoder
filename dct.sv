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
logic [31:0] s1_output[8][8];
logic sl_output_enable[8];

genvar i;
generate
	for(i=0;i<8;i=i+1) begin
		dct_butterfly butterfly1(
			.CLOCK(CLOCK),
			.RESET(RESET),
			.ENABLE(INPUT_DATA_ENABLE),
			.DATA(INPUT_DATA[i]),
			.OUT_ENABLE(sl_output_enable[i]),
			.OUT_DATA(s1_output[i])
		);
	end
endgenerate

logic [31:0] tmp_data[8][8];

genvar  j,k;
for(j=0;j<8;j++) begin
	for(k=0;k<8;k++) begin
			assign tmp_data[k][j] = s1_output[j][k];
	end
end

logic [7:0] s2_enable;

/*
integer m;
for (m=0;m<8;m++) begin
	logic [7:0]	s1_output_bit;
end
*/

always @(posedge CLOCK) begin
	if (RESET==1'b0)	begin
		s2_enable = 8'b0;
	end else begin
		if (sl_output_enable[0]) begin
			s2_enable |= 8'b1;
		end
		if (sl_output_enable[1]) begin
			s2_enable |= 8'b10;
		end
		if (sl_output_enable[2]) begin
			s2_enable |= 8'b100;
		end
		if (sl_output_enable[3]) begin
			s2_enable |= 8'b1000;
		end
		if (sl_output_enable[4]) begin
			s2_enable |= 8'b10000;
		end
		if (sl_output_enable[5]) begin
			s2_enable |= 8'b100000;
		end
		if (sl_output_enable[6]) begin
			s2_enable |= 8'b1000000;
		end
		if (sl_output_enable[7]) begin
			s2_enable |= 8'b10000000;
		end

	end
end
logic s2_enable_all;

always @(posedge CLOCK) begin
	if (RESET==1'b0) begin
		s2_enable_all <= 1'b0;
	end else begin
		if (s2_enable == 8'b11111111) begin
			s2_enable_all <= 1'b1;
		end else begin
//			s2_enable_all <= 1'b1;
		end

	end
end

logic s3_output_enable[8];
logic [31:0] s3_output[8][8];


genvar l;
generate
	for(l=0;l<8;l=l+1) begin
		dct_butterfly butterfly2(
			.CLOCK(CLOCK),
			.RESET(RESET),
			.ENABLE(s2_enable_all),
			.DATA(tmp_data[l]),
			.OUT_ENABLE(s3_output_enable[l]),
			.OUT_DATA(s3_output[l])
		);
	end
endgenerate


logic [7:0] s3_enable;

always @(posedge CLOCK) begin
	if (RESET==1'b0)	begin
		s3_enable = 8'b0;
	end else begin
		if (s3_output_enable[0]) begin
			s3_enable |= 8'b1;
		end
		if (s3_output_enable[1]) begin
			s3_enable |= 8'b10;
		end
		if (s3_output_enable[2]) begin
			s3_enable |= 8'b100;
		end
		if (s3_output_enable[3]) begin
			s3_enable |= 8'b1000;
		end
		if (s3_output_enable[4]) begin
			s3_enable |= 8'b10000;
		end
		if (s3_output_enable[5]) begin
			s3_enable |= 8'b100000;
		end
		if (s3_output_enable[6]) begin
			s3_enable |= 8'b1000000;
		end
		if (s3_output_enable[7]) begin
			s3_enable |= 8'b10000000;
		end

	end
end
logic s3_enable_all;

always @(posedge CLOCK) begin
	if (RESET==1'b0) begin
		s3_enable_all <= 1'b0;
	end else begin
		if (s3_enable == 8'b11111111) begin
			s3_enable_all <= 1'b1;
		end else begin
//			s2_enable_all <= 1'b1;
		end

	end
end



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
assign OUTPUT_DATA_ENABLE  = s3_enable_all;
endmodule
