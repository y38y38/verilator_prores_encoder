module entropy_encode_ac_level_coefficients(
	input clk,
	input reset_n,

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	input  signed [31:0]  Coeff,
	
	output reg [31:0] sum_n_n,
	output reg [31:0] codeword_length_n_n



);

reg [31:0] Coeff_n;
reg [31:0] output_enable;//mask
reg [31:0] sum;
reg [31:0] codeword_length;
reg [31:0] sum_n;
reg [31:0] codeword_length_n;
reg [31:0] previousLevel;
reg signed [31:0] abs_level_minus_1;
reg signed [31:0] abs_level_minus_1_n;
reg [1:0] is_expo_golomb_code;
reg [1:0] is_expo_golomb_code_n;
reg [1:0] is_expo_golomb_code_n_n;
reg [1:0] is_add_setbit;
reg [2:0] k;
reg [31:0] q;
reg first;
reg is_minus;
reg is_minus_n;



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
		end 
		is_minus_n <= is_minus;
	end
end

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		abs_level_minus_1 <= 32'h0;
		Coeff_n <= 32'h1;
	end else begin
		if (Coeff != 0) begin
			if (Coeff[31] != 1'b1) begin
				abs_level_minus_1 <= Coeff - 1;//1clk
			end else begin
				abs_level_minus_1 <=  (~(Coeff - 1)) - 1;
			end
			Coeff_n <= 32'h1;
		end else begin
			Coeff_n <= 32'h0;
		end
	end
end

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		previousLevel <= 32'h1;
		is_expo_golomb_code <= 2'h2;
		abs_level_minus_1_n <= 32'h0;
		first <=1'b1;

	end else begin
		if (first) begin
			previousLevel <= 32'h1;
			is_expo_golomb_code <= 2'h2;
			first <=1'b0;
		end else if (Coeff_n == 32'h0) begin
			is_expo_golomb_code <= 2'h2;
		end else begin
			if (previousLevel == 0)  begin
				if (abs_level_minus_1 < 3) begin
					is_expo_golomb_code <= 2'b0;//2clk
					is_add_setbit<=2'h0;
					k <= 0;
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
			previousLevel <= abs_level_minus_1;

		end

	end
end





wire [31:0] exp_golomb_sum;
wire [31:0] exp_golomb_codeword_length;

exp_golomb_code exp_golomb_code_inst(
	.reset_n(reset_n),
	.clk(clk),
	.val(abs_level_minus_1_n),
	.is_add_setbit(is_add_setbit),
	.k(k),
	.is_ac_level(1),
	.is_ac_minus_n(is_minus_n),

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
	.val(abs_level_minus_1_n),
	.is_ac_level(1),
	.is_minus_n(is_minus_n),

	//output
	.sum_n(rice_sum),
	.codeword_length(rice_codeword_length)

);

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_expo_golomb_code_n <= 2'h2;
		is_expo_golomb_code_n_n <= 2'h2;
	end else begin
		is_expo_golomb_code_n <= is_expo_golomb_code;//3clk
		is_expo_golomb_code_n_n <= is_expo_golomb_code_n;//4clk
	end
end


always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		sum_n_n <= 32'h0;
		codeword_length_n_n <= 32'h0;
	end else begin
		if (is_expo_golomb_code_n_n == 2'b00) begin
			sum_n_n <= rice_sum;
			codeword_length_n_n <= rice_codeword_length;//5clk
		end else if (is_expo_golomb_code_n_n == 2'b01) begin
			sum_n_n <= exp_golomb_sum;
			codeword_length_n_n <= exp_golomb_codeword_length;
		end else if (is_expo_golomb_code_n_n == 2'b10) begin
			sum_n_n <= 0;
			codeword_length_n_n <= 0;
		end
	end
end


endmodule;
