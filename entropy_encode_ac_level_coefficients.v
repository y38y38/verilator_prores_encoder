`timescale 1ns / 1ps

module entropy_encode_ac_level_coefficients(
	input clk,
	input reset_n,

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	input  signed [19:0]  Coeff,
	output reg [23:0] output_enable,//mask
	output reg [23:0] sum,
	output reg [31:0] codeword_length,

output reg [19:0] previousLevel,
output reg signed [19:0] abs_level_minus_1,
output reg signed [19:0] abs_level_minus_1_n,
output reg [1:0] is_expo_golomb_code,
output reg [1:0] is_add_setbit,
output reg [2:0] k,
output reg [31:0] q,
output reg first,
output reg is_minus,
output reg is_minus_n

);

function [19:0] getabs;
	input [19:0] value;
	begin
		if (value[19] != 1'b1) begin
			getabs = value;
		end else begin
			getabs =  (~(value - 1));
		end
	end
endfunction

function [31:0] getfloorclog2;
	input [19:0] val;
	begin
		reg [19:0] in_val;
		in_val = val;
		for (getfloorclog2=0; in_val>0; getfloorclog2=getfloorclog2+1) begin
			in_val = in_val>>1;
		end
		getfloorclog2 = getfloorclog2 - 1;
	end
endfunction



function [23:0] bitmask;
	input [5:0] val;
	reg [5:0] index = 6'h0;
	begin
		bitmask = 24'h1;
		for(index=1;index<val;index=index+1) begin
			bitmask = (bitmask<<1) | 1;
		end
	end
endfunction

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_minus <= 1'b0;
	end else begin
		if (Coeff != 0) begin
			if (Coeff < 0) begin
				is_minus <= 1'b1;
			end else begin
				is_minus <= 1'b0;
			end
			is_minus_n <= is_minus;
			
		end
	end
end


always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		previousLevel <= 20'h1;
		is_expo_golomb_code <= 2'h2;
		abs_level_minus_1 <= 20'h0;
		abs_level_minus_1_n <= 20'h0;
		first <=1'b1;

	end else begin
		if (Coeff != 0) begin
			abs_level_minus_1 <= getabs(Coeff) -1;
			if (first) begin
				previousLevel <= 20'h1;
				is_expo_golomb_code <= 2'h2;
				first <=1'b0;
			end else begin
				previousLevel <= abs_level_minus_1;
				if (previousLevel == 0)  begin
					if (abs_level_minus_1 < 3) begin
						is_expo_golomb_code <= 2'b0;
						is_add_setbit<=2'h0;
						k <= 0;

						//golomb_rice_codeの場合qをif文で使用するため、1clock前の代入が必要
						q = abs_level_minus_1;
						abs_level_minus_1_n <= abs_level_minus_1;
					end else begin
						is_expo_golomb_code <= 2'b1;
						is_add_setbit<=2'h3;
						k <= 2;
						abs_level_minus_1_n <= abs_level_minus_1 - 3;
					end
				end else if (previousLevel == 1) begin
					if (abs_level_minus_1 < 2) begin
						is_expo_golomb_code <= 2'b0;
						is_add_setbit<=2'h0;
						k <= 0;
						q = abs_level_minus_1;
						abs_level_minus_1_n <= abs_level_minus_1;

					end else begin
						is_expo_golomb_code <= 2'b1;
						is_add_setbit<=2'h2;
						k <= 1;
						abs_level_minus_1_n <= abs_level_minus_1 - 2;
					end
				end else if ((previousLevel == 2)) begin
					if (abs_level_minus_1 < 3) begin
						is_expo_golomb_code <= 2'b0;
						is_add_setbit<=2'h0;
						k <= 0;
						q = abs_level_minus_1;
						abs_level_minus_1_n <= abs_level_minus_1;

					end else begin
						is_expo_golomb_code <= 2'b1;
						is_add_setbit<=2'h3;
						k <= 1;
						abs_level_minus_1_n <= abs_level_minus_1 - 3;
					end
				end else if (previousLevel == 3) begin
					is_expo_golomb_code <= 2'b1;
					is_add_setbit <= 2'h0;
					k <= 0;
						abs_level_minus_1_n <= abs_level_minus_1;
				end else if ((previousLevel >= 4) && (previousLevel <= 7)) begin
					is_expo_golomb_code <= 2'b1;
					is_add_setbit <= 2'h0;
					k <= 1;
						abs_level_minus_1_n <= abs_level_minus_1;
				end else begin
					is_expo_golomb_code <= 2'b1;
					is_add_setbit <= 2'h0;
					k <= 2;
						abs_level_minus_1_n <= abs_level_minus_1;
				end
			end
		end else begin
			is_expo_golomb_code <= 2'b10;

		end

	end
end





//assign LENGTH = codeword_length;


//reg [31:0] codeword_length = 32'h0;

//exp_golomb_code
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		output_enable = 24'h0;
		sum = 24'h0;
	end else begin
		if (is_expo_golomb_code == 2'b1) begin
			q = getfloorclog2((abs_level_minus_1_n + (1<<(k)))) - k;
			//q =  input_data + 16'h1;
			if (is_minus_n) begin
				sum[19:0] = (abs_level_minus_1_n + (1<<k))<<1|1;
			end else begin
				sum[19:0] = (abs_level_minus_1_n + (1<<k))<<1|0;
			end
//			if (is_add_setbit == 1'b1) begin
				//dd
				codeword_length = (2 * q) + k + 2 + is_add_setbit;
//			end else begin
//				codeword_length = (2 * q) + k + 1;
//			end
			output_enable = bitmask(codeword_length);
		end
	end
end


//golomb_rice_code
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		output_enable = 24'h0;
		sum = 24'h0;
		codeword_length = 32'h0;
	end else begin
		if (is_expo_golomb_code == 2'b0) begin
			//q=と、if(qのタイミング)
//			q = abs_level_minus_1 >> k;
			if (k==0) begin
				if(q!=0) begin
					if (is_minus_n) begin
						sum = 3;
						
					end else begin
						sum = 2;
					end
					codeword_length = q+2;
					output_enable = bitmask(codeword_length);
				end else begin
					if (is_minus_n) begin
						sum = 3;
						
					end else begin
						sum = 2;
					end
					codeword_length = 2;
					output_enable = 1;
				end
			end else begin
				// 0x4 | 1 & 0x3
				// 0x5 
				if (is_minus_n) begin
					sum = (1<<k) | (abs_level_minus_1_n & ((1<<k) - 1));
					sum = sum<<1|1;
				end else begin
					sum = sum<<1|0;
				end

//				sum = 20'h111 ;//(1<<k) | (abs_level_minus_1 & ((1<<k) - 1));
				codeword_length = q + 2 + k;
				output_enable = bitmask( codeword_length);	
			end
		end
	end
end

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
	end else begin
		if (is_expo_golomb_code == 2'h2) begin
			sum = 0;
			codeword_length = 0;
			output_enable = 0;
		end
	end
end



endmodule;
