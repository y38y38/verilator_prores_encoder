`timescale 1ns / 1ps

module entropy_encode_dc_coefficients(
	input clk,
	input reset_n,

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	input [31:0] DcCoeff,

output reg [31:0] sum_n_n,
output reg [31:0] codeword_length_n




);

reg [31:0] previousDCDiff;
reg [31:0] sum;
reg [31:0] sum_n;
wire [31:0] LENGTH;
reg [31:0] pppp;
reg [31:0] abs_previousDCDiff;
reg [31:0] abs_previousDCDiff_next; 
reg [31:0] abs_previousDCDiff_next_next; 
reg [31:0] previousDCCoeff;
reg [31:0] dc_coeff_difference; 
reg [31:0] val;
reg [31:0] val_n;
reg [1:0] is_expo_golomb_code;
reg [1:0] is_expo_golomb_code_n;
reg [1:0] is_expo_golomb_code_n_n;
reg [1:0] is_add_setbit;
reg [1:0] is_add_setbit_n;
reg [2:0] k;
reg [2:0] k_n;
reg [31:0] q = 32'h0;
reg [31:0] codeword_length = 32'h0;
reg first_diff;



always @(posedge clk) begin
	if (!reset_n) begin
		first_diff <= 1;
		previousDCCoeff <= 32'h0;
	end else begin
		previousDCCoeff <= DcCoeff;
	end
end


//always @(posedge clk, negedge reset_n) begin
always @(posedge clk) begin
	if (!reset_n) begin
		dc_coeff_difference <= 32'h0;
		val <= 32'h0;
		previousDCDiff <= 32'h3;

	end else begin
		if (previousDCDiff[31] == 1'b0) begin
			dc_coeff_difference <= DcCoeff - previousDCCoeff;
		end else begin
			dc_coeff_difference <= (~(DcCoeff - previousDCCoeff)) + 1;
		end

		if (dc_coeff_difference[31] != 1'b1) begin
			val <= dc_coeff_difference << 1;
		end else begin
			val <= ((~(dc_coeff_difference - 1)) << 1) -1;
		end

		if (first_diff) begin
			previousDCDiff <= 3;
			first_diff <=0;
			
		end else begin
			previousDCDiff <= DcCoeff - previousDCCoeff;
			
		end
	end

end



//get abs
always @(posedge clk ) begin
	if (!reset_n) begin
		abs_previousDCDiff <= 32'h0;
	end else begin
		if (previousDCDiff[31] != 1'b1) begin
			abs_previousDCDiff <= previousDCDiff;
		end else begin
			abs_previousDCDiff <= (~(previousDCDiff - 1));
		end
		abs_previousDCDiff_next <= abs_previousDCDiff;
		abs_previousDCDiff_next_next <= abs_previousDCDiff_next;

	end
end




reg first;
reg first_n;
reg first_n_n;

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		first <= 1'b1;
	end else begin
		first <=0;
		first_n <=first;
		first_n_n <= first_n;
	end
end


//dicision talbe

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_expo_golomb_code <= 2'b10;
		is_add_setbit <= 2'b0;
		k <= 3'h0;
		val_n <= 32'h0;

	end else begin
		if (first_n_n == 1'b1) begin
			is_expo_golomb_code <= 2'b01;
			is_add_setbit <= 2'b0;
			k <= 5;
			val_n <= val;
		end else if (abs_previousDCDiff_next == 0) begin
			is_expo_golomb_code <= 2'b01;
			is_add_setbit <= 2'b0;
			k <= 0;
			val_n <= val;
		end else if (abs_previousDCDiff_next == 1) begin
			is_expo_golomb_code <= 2'b01;
			is_add_setbit <= 2'b0;
			k <= 1;
			val_n <= val;
		end else if (abs_previousDCDiff_next== 2) begin
			//uint32_t value = (last_rice_q + 1) << k_rice;
			if (val < 8) begin
				is_expo_golomb_code <= 2'b00;
				is_add_setbit <= 2'b0;
				k <= 2;
				val_n <= val;
			end else begin
				is_expo_golomb_code <= 2'b01;
		        //setBit(bitstream, 0,last_rice_q + 1);
				is_add_setbit <= 2'b10;
				k <= 3;
				val_n <= val -8;
			end
			
		end else begin
			is_expo_golomb_code <= 2'b01;
			is_add_setbit <= 2'b0;
			k <= 3;
			val_n <= val;
		end
			
	end
end

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_expo_golomb_code_n <= 2'b10;
	end else begin
		is_expo_golomb_code_n <= is_expo_golomb_code;
	end
end





assign LENGTH = codeword_length;
/*
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		previousDCDiff <= 32'hffff; 
	end else begin
		
	end
end
*/


wire [31:0] exp_golomb_sum;
wire [31:0] exp_golomb_codeword_length;

exp_golomb_code exp_golomb_code_inst(
	.reset_n(reset_n),
	.clk(clk),
	.val(val_n),
	.is_add_setbit(is_add_setbit),
	.k(k),
	.is_ac_level(0),
	.is_ac_minus_n(0),

	//output
	.sum_n(exp_golomb_sum),
	.codeword_length(exp_golomb_codeword_length)
);


wire [31:0] rice_sum;
wire [31:0] rice_codeword_length;

golomb_rice_code golomb_rice_code_inst(
	.reset_n(reset_n),
	.clk(clk),
	.k(k),
	.val(val_n),
	.is_ac_level(0),
	.is_minus_n(0),


	//output
	.sum_n(rice_sum),
	.codeword_length(rice_codeword_length)

);

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_expo_golomb_code_n_n <= 2'b00;
	end else begin
		is_expo_golomb_code_n_n <= is_expo_golomb_code_n;
	end
end

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		sum_n_n <= 32'h0;
		codeword_length_n <= 32'h0;
	end else begin
		if (is_expo_golomb_code_n_n == 2'b00) begin
			sum_n_n <= rice_sum;
			codeword_length_n <= rice_codeword_length;
		end else if (is_expo_golomb_code_n_n == 2'b01) begin
			sum_n_n <= exp_golomb_sum;
			codeword_length_n <= exp_golomb_codeword_length;
		end else if (is_expo_golomb_code_n_n == 2'b10) begin
			sum_n_n <= sum_n;
			codeword_length_n <= codeword_length;
		end
	end
end





always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
	end else begin
		if (is_expo_golomb_code == 2'b10) begin
			codeword_length <= 32'h0;
			sum <= 32'h0;
		end
	end
end





endmodule;
