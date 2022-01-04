module entropy_encode_ac_level_coefficients(
	input clk,
	input reset_n,

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	input wire input_start,
	input wire input_valid,
	input wire input_end,
	
	input  signed [31:0]  Coeff,
	
	output reg output_start,
	output reg output_valid,
	output reg output_end,

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
//reg [1:0] is_expo_golomb_code;
//reg [1:0] is_expo_golomb_code_n;
//reg [1:0] is_expo_golomb_code_n_n;
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

reg valid_1clk;
reg start_1clk;
reg end_1clk;

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		abs_level_minus_1 <= 32'h0;
		Coeff_n <= 32'h1;
		valid_1clk <= 1'b0;
		start_1clk <= 1'b0;
		end_1clk <= 1'b0;
	end else begin
		if (Coeff != 0) begin
			if (Coeff[31] != 1'b1) begin
				abs_level_minus_1 <= Coeff - 1;//1clk
			end else begin
				abs_level_minus_1 <=  (~(Coeff - 1)) - 1;
			end
			Coeff_n <= 32'h1;
			valid_1clk <= input_valid;
			start_1clk <= input_start;
			end_1clk <= input_end;
		end else begin
			Coeff_n <= 32'h0;
			valid_1clk <= 1'b0;
			start_1clk <= input_start;
			end_1clk <= input_end;
		end
	end
end


reg exp_golomb_code_valid;
reg rice_golomb_code_valid;


reg valid_2clk;
reg start_2clk;
reg end_2clk;

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		previousLevel <= 32'h1;
		exp_golomb_code_valid <= 1'b0;
		rice_golomb_code_valid <= 1'b0;
//		is_expo_golomb_code <= 2'h2;

		abs_level_minus_1_n <= 32'h0;
		first <=1'b1;
		valid_2clk <= 1'b0;

	end else begin
		$display("level %d %d %d , %d %d %d",input_valid, input_start, input_end, output_valid, output_start, output_end);

		valid_2clk <= valid_1clk;
		start_2clk <= start_1clk;
		end_2clk <= end_1clk;
		if (first) begin
			previousLevel <= 32'h1;
//			is_expo_golomb_code <= 2'h2;
			rice_golomb_code_valid <= 1'b0;
			exp_golomb_code_valid <= 1'b0;


			first <=1'b0;
		end else if (Coeff_n == 32'h0) begin
//			is_expo_golomb_code <= 2'h2;
			rice_golomb_code_valid <= 1'b0;
			exp_golomb_code_valid <= 1'b0;
		end else begin
			if (previousLevel == 0)  begin
				if (abs_level_minus_1 < 3) begin
//					is_expo_golomb_code <= 2'b0;//2clk
			rice_golomb_code_valid <= valid_1clk;
			exp_golomb_code_valid <= 1'b0;

					is_add_setbit<=2'h0;
					k <= 0;
					abs_level_minus_1_n <= abs_level_minus_1;
				end else begin
//					is_expo_golomb_code <= 2'b1;
			rice_golomb_code_valid <= 1'b0;
			exp_golomb_code_valid <= valid_1clk;


					is_add_setbit<=2'h3;
					k <= 2;
					abs_level_minus_1_n <= abs_level_minus_1 - 3;
				end
			end else if (previousLevel == 1) begin
				if (abs_level_minus_1 < 2) begin
//					is_expo_golomb_code <= 2'b0;
			rice_golomb_code_valid <= valid_1clk;
			exp_golomb_code_valid <= 1'b0;


					is_add_setbit<=2'h0;
					k <= 0;
					abs_level_minus_1_n <= abs_level_minus_1;
				end else begin
//					is_expo_golomb_code <= 2'b1;
			rice_golomb_code_valid <= 1'b0;
			exp_golomb_code_valid <= valid_1clk;


					is_add_setbit<=2'h2;
					k <= 1;
					abs_level_minus_1_n <= abs_level_minus_1 - 2;
				end
			end else if ((previousLevel == 2)) begin
				if (abs_level_minus_1 < 3) begin
//					is_expo_golomb_code <= 2'b0;
			rice_golomb_code_valid <= valid_1clk;
			exp_golomb_code_valid <= 1'b0;



					is_add_setbit<=2'h0;
					k <= 0;
					abs_level_minus_1_n <= abs_level_minus_1;
				end else begin
//					is_expo_golomb_code <= 2'b1;
			rice_golomb_code_valid <= 1'b0;
			exp_golomb_code_valid <= valid_1clk;


					is_add_setbit<=2'h3;
					k <= 1;
					abs_level_minus_1_n <= abs_level_minus_1 - 3;
				end
			end else if (previousLevel == 3) begin
//				is_expo_golomb_code <= 2'b1;
			rice_golomb_code_valid <= 1'b0;
			exp_golomb_code_valid <= valid_1clk;


				is_add_setbit <= 2'h0;
				k <= 0;
				abs_level_minus_1_n <= abs_level_minus_1;
			end else if ((previousLevel >= 4) && (previousLevel <= 7)) begin
//				is_expo_golomb_code <= 2'b1;
			rice_golomb_code_valid <= 1'b0;
			exp_golomb_code_valid <= valid_1clk;


				is_add_setbit <= 2'h0;
				k <= 1;
				abs_level_minus_1_n <= abs_level_minus_1;
			end else begin
//				is_expo_golomb_code <= 2'b1;
			rice_golomb_code_valid <= 1'b0;
			exp_golomb_code_valid <= valid_1clk;


				is_add_setbit <= 2'h0;
				k <= 2;
				abs_level_minus_1_n <= abs_level_minus_1;
			end
			previousLevel <= abs_level_minus_1;

		end
	//	$display("valid %d %d %d %d",rice_golomb_code_valid,  exp_golomb_code_valid, valid_1clk, input_valid);

	end
end


wire rice_output_valid;
wire exp_output_valid;

wire rice_output_start;
wire rice_output_end;

wire exp_output_start;
wire exp_output_end;


wire [31:0] exp_golomb_sum;
wire [31:0] exp_golomb_codeword_length;

reg valid_3clk;
reg valid_4clk;

exp_golomb_code exp_golomb_code_inst(
	.reset_n(reset_n),
	.clk(clk),

	.input_start(start_2clk),
	.input_end(end_2clk),
	.input_valid(exp_golomb_code_valid),

	.val(abs_level_minus_1_n),
	.is_add_setbit(is_add_setbit),
	.k(k),
	.is_ac_level(1),
	.is_ac_minus_n(is_minus_n),

	//output
	.output_valid(exp_output_valid),
	.sum_n(exp_golomb_sum),
	.codeword_length(exp_golomb_codeword_length),

	.output_start(exp_output_start),
	.output_end(exp_output_end)

);

wire [31:0] rice_sum;
wire [31:0] rice_codeword_length;

golomb_rice_code golomb_rice_code_inst(
	.reset_n(reset_n),
	.clk(clk),

	.input_start(start_2clk),
	.input_end(end_2clk),
	.input_valid(rice_golomb_code_valid),
	.k(k),
	.val(abs_level_minus_1_n),
	.is_ac_level(1),
	.is_minus_n(is_minus_n),

	//output
	.output_valid(rice_output_valid),
	.sum_n(rice_sum),
	.codeword_length(rice_codeword_length),

	.output_start(rice_output_start),
	.output_end(rice_output_end)


);


/*
always @(posedge clk, negedge reset_n) begin

	if (!reset_n) begin
		is_expo_golomb_code_n <= 2'h2;
		is_expo_golomb_code_n_n <= 2'h2;
	end else begin
		is_expo_golomb_code_n <= is_expo_golomb_code;//3clk
		is_expo_golomb_code_n_n <= is_expo_golomb_code_n;//4clk

		valid_3clk <= valid_2clk;
		valid_4clk <= valid_3clk;
	end
end
*/

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		sum_n_n <= 32'h0;
		codeword_length_n_n <= 32'h0;
		output_valid <= 1'b0;
		output_start <= 1'b0;
		output_end <= 1'b0;
	
	end else begin
/*		
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
*/
		if (rice_output_valid == 1'b1) begin
			sum_n_n <= rice_sum;
			codeword_length_n_n <= rice_codeword_length;//5clk
			output_valid <= 1'b1;
		end else if (exp_output_valid == 1'b1) begin
			sum_n_n <= exp_golomb_sum;
			codeword_length_n_n <= exp_golomb_codeword_length;
			output_valid <= 1'b1;
		end else  begin
			sum_n_n <= 0;
			codeword_length_n_n <= 0;
			output_valid <= 1'b0;
		end
		output_start <= rice_output_start | exp_output_start;
		output_end <= rice_output_end | exp_output_end;
	//	$display("level %d", output_valid);
	end
end


endmodule
