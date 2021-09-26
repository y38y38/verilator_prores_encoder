`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/11/2021 08:37:03 PM
// Design Name: 
// Module Name: dct
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

module dct_butterfly(
	input CLOCK,
	input RESET,
	input [31:0] DATA[8],
	output [31:0] OUT_DATA[8]
    );

	reg signed [31:0] s1[8];
	reg stage1_out_enable;


	always @(posedge CLOCK ) begin
		if (RESET == 1'b0) begin
			s1[0] <=32'h0;
			s1[1] <=32'h0;
			s1[2] <=32'h0;
			s1[3] <=32'h0;
			s1[4] <=32'h0;
			s1[5] <=32'h0;
			s1[6] <=32'h0;
			s1[7] <=32'h0;

		end else begin
			s1[0] <=DATA[0] + DATA[7];
			s1[1] <=DATA[1] + DATA[6];
			s1[2] <=DATA[2] + DATA[5];
			s1[3] <=DATA[3] + DATA[4];
			s1[4] <=DATA[3] - DATA[4];
			s1[5] <=DATA[2] - DATA[5];
			s1[6] <=DATA[1] - DATA[6];
			s1[7] <=DATA[0] - DATA[7];
			stage1_out_enable <= 1'b1;
		end
	end

	reg signed [31:0] s2[8];

	localparam MATH_COS_PI_4  = 46340;

	always @(posedge CLOCK ) begin
		if (RESET == 1'b0) begin
			s2[0] <=32'h0;
			s2[1] <=32'h0;
			s2[2] <=32'h0;
			s2[3] <=32'h0;
			s2[4] <=32'h0;
			s2[5] <=32'h0;
			s2[6] <=32'h0;
			s2[7] <=32'h0;

		end else begin
			s2[0] <=s1[0] + s1[3];
			s2[1] <=s1[1] + s1[2];
			s2[2] <=s1[1] - s1[2];
			s2[3] <=s1[0] - s1[3];
			s2[4] <=s1[4];
			s2[5] <=(((s1[6] * MATH_COS_PI_4)>>>16) - ((s1[5] * MATH_COS_PI_4) >>> 16));
			s2[6] <=((s1[6] * MATH_COS_PI_4)>>>16) + ((s1[5] * MATH_COS_PI_4)>>> 16);
			s2[7] <=s1[7];
		end
	end

	reg signed [31:0] s3[8];

	localparam MATH_SIN_PI_8  = 25079;
	localparam MATH_COS_PI_8  = 60547;
	localparam MATH_COS_3_PI_8  = 25079;
	localparam MATH_SIN_3_PI_8  = 60547;

	always @(posedge CLOCK ) begin
		if (RESET == 1'b0) begin
			s3[0] <=32'h0;
			s3[1] <=32'h0;
			s3[2] <=32'h0;
			s3[3] <=32'h0;
			s3[4] <=32'h0;
			s3[5] <=32'h0;
			s3[6] <=32'h0;
			s3[7] <=32'h0;

		end else begin
			s3[0] <=((s2[0] * MATH_COS_PI_4)>>>16) + ((s2[1] * MATH_COS_PI_4)>>>16);
			
			s3[1] <=((s2[0] * MATH_COS_PI_4)>>>16) - ((s2[1] * MATH_COS_PI_4)>>>16);
			s3[2] <=((s2[2] * MATH_SIN_PI_8)>>>16) + ((s2[3] * MATH_COS_PI_8)>>>16);
			s3[3] <=((s2[3] * MATH_COS_3_PI_8)>>>16) - ((s2[2] * MATH_SIN_3_PI_8)>>>16);
			s3[4] <=s2[4] + s2[5];
			s3[5] <=s2[4] - s2[5];
			s3[6] <=s2[7] - s2[6];
			s3[7] <=s2[6] + s2[7];
		end
	end

	reg signed [31:0] s4[8];

	localparam MATH_SIN_PI_16  = 12785;
	localparam MATH_COS_PI_16  = 64276;
	localparam MATH_SIN_5_PI_16  = 54491;
	localparam MATH_COS_5_PI_16  = 36409;
	localparam MATH_COS_3_PI_16  = 54491;
	localparam MATH_SIN_3_PI_16  = 36409;
	localparam MATH_COS_7_PI_16  = 12785;
	localparam MATH_SIN_7_PI_16  = 62276;

	always @(posedge CLOCK ) begin
		if (RESET == 1'b0) begin
			s4[0] <=32'h0;
			s4[1] <=32'h0;
			s4[2] <=32'h0;
			s4[3] <=32'h0;
			s4[4] <=32'h0;
			s4[5] <=32'h0;
			s4[6] <=32'h0;
			s4[7] <=32'h0;

		end else begin

			s4[0] <= s3[0];
			s4[1] <= s3[1];
			s4[2] <= s3[2];
			s4[3] <= s3[3];
			s4[4] <= ((s3[4] * MATH_SIN_PI_16>>>16)) + ((s3[7] * MATH_COS_PI_16)>>>16);
			s4[5] <= ((s3[5] * MATH_SIN_5_PI_16)>>>16) + ((s3[6] * MATH_COS_5_PI_16)>>>16);

			s4[6] <= ((s3[6] * MATH_COS_3_PI_16)>>>16) - ((s3[5] * MATH_SIN_3_PI_16)>>>16);

			s4[7] <= ((s3[7] * MATH_COS_7_PI_16)>>>16) - ((s3[4] * MATH_SIN_7_PI_16)>>>16);
		end
	end

	reg signed [31:0] s5[8];

	always @(posedge CLOCK ) begin
		if (RESET == 1'b0) begin
			s5[0] <=32'h0;
			s5[1] <=32'h0;
			s5[2] <=32'h0;
			s5[3] <=32'h0;
			s5[4] <=32'h0;
			s5[5] <=32'h0;
			s5[6] <=32'h0;
			s5[7] <=32'h0;
		end else begin
			s5[0] <= s4[0] >>>1;
			s5[1] <= s4[4] >>>1;
			s5[2] <= s4[2] >>>1;
			s5[3] <= s4[6] >>>1;
			s5[4] <= s4[1] >>>1;
			s5[5] <= s4[5] >>>1;
			s5[6] <= s4[3] >>>1;
			s5[7] <= s4[7] >>>1;
		end
	end


	assign OUT_DATA[0] = s5[0];
	assign OUT_DATA[1] = s5[1];
	assign OUT_DATA[2] = s5[2];
	assign OUT_DATA[3] = s5[3];
	assign OUT_DATA[4] = s5[4];
	assign OUT_DATA[5] = s5[5];
	assign OUT_DATA[6] = s5[6];
	assign OUT_DATA[7] = s5[7];
endmodule
