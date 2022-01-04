`timescale 1ns / 1ps
module golomb_rice_code(
	input reset_n,
	input clk,

	input input_start,
	input input_valid,
	input input_end,

	input [2:0] k,
	input [31:0] val,
	input is_ac_level,
	input is_minus_n,

	output wire output_start,
	output wire output_valid,
	output wire output_end,
	
	output reg [31:0] sum_n,
	output reg [31:0] codeword_length

 );

	//internal reg
 reg is_minus_n_n;
 reg is_ac_level_n;
 reg [31:0] q;
 reg  [2:0] k_n;
 reg [31:0] sum;


always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_minus_n_n <= 1'b0;
		is_ac_level_n <= 1'b0;
	end else begin
		is_minus_n_n <= is_minus_n;
		is_ac_level_n <= is_ac_level;		
	end
end

reg valid_2clk;
reg start_2clk;
reg end_2clk;

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		sum_n <= 32'h0;
		k_n <= 3'h0;
		valid_2clk <= 1'b0;
		start_2clk <= 1'b0;
		end_2clk <= 1'b0;
	end else begin
		if (k_n!= 0) begin
			sum_n <= sum;
		end
		k_n <= k;
		valid_2clk <= valid_1clk;
		start_2clk <= start_1clk;
		end_2clk <= end_1clk;
	end
end

assign output_valid = valid_2clk;
assign output_start = start_2clk;
assign output_end = end_2clk;

reg valid_1clk;
reg start_1clk;
reg end_1clk;

//golomb_rice_code
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		sum <= 32'h0;
		valid_1clk <= 1'b0;
		start_1clk <= 1'b0;
		end_1clk <= 1'b0;
	end else begin
		q <= val >> k;
		if (k != 0) begin
			if (is_ac_level) begin
				if (is_minus_n) begin
					sum <= (((1<<k) | (val & ((1<<k) - 1))) << 1)|1;
					
				end else begin
					sum <= (((1<<k) | (val & ((1<<k) - 1))) << 1)|0;
				end
				
			end else begin
				sum <= (1<<k) | (val & ((1<<k) - 1));
			end
		end
		valid_1clk <= input_valid;
		start_1clk <= input_start;
		end_1clk <= input_end;
	end
end

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		codeword_length <= 32'h0;
	end else begin
		if (k_n==0) begin
			if (is_ac_level_n) begin
				if (is_minus_n_n) begin
					sum_n <= 3;
				end else begin
					sum_n <= 2;
				end
				codeword_length <= q + 2;
			end else begin
				sum_n <= 1;
				codeword_length <= q + 1;
			end
		end else begin
			if (is_ac_level_n) begin
				codeword_length <= q + 2 + {29'h0, k_n};
			end else begin
				codeword_length <= q + 1 + {29'h0, k_n};
			end
		end
	end
end


endmodule

