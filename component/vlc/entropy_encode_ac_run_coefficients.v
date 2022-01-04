module entropy_encode_ac_run_coefficients(
	input clk,
	input reset_n,

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	input wire input_start,
	input wire input_end,
	input wire input_enable,
	input [31:0] Coeff,

	output reg output_start_n,
	output reg output_end_n,
	output reg output_valid_n,
	output reg [31:0] sum_n_n_n,
	output reg [31:0] codeword_length_n_n_n



);

//reg [31:0] sum;
reg [31:0] sum_n;
reg [31:0] sum_n_n;
reg [31:0] codeword_length;
reg [31:0] codeword_length_n;
reg [31:0] codeword_length_n_n;
reg [31:0] previousRun;
reg signed [31:0] run;
reg signed [31:0] run_n;
//reg [1:0] is_expo_golomb_code;
//reg [1:0] is_expo_golomb_code_n;
//reg [1:0] is_expo_golomb_code_n_n;
reg [1:0] is_add_setbit;
reg [2:0] k;

wire [31:0] exp_golomb_sum;
wire [31:0] exp_golomb_codeword_length;
wire [31:0] rice_sum;
wire [31:0] rice_codeword_length;

reg [31:0] q;

reg valid_1clk;
reg start_1clk;
reg end_1clk;


reg exp_golomb_code_valid;
reg rice_golomb_code_valid;

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		previousRun <= 32'h4;
		run <= 32'h0;
//		is_expo_golomb_code <= 2'h2;
		valid_1clk <= 1'h0;
		start_1clk <=1'h0;
		end_1clk <=1'h0;
		exp_golomb_code_valid <= 1'b0;
		rice_golomb_code_valid <= 1'b0;

	end else begin
		$display("run   %d %d %d , %d %d %d",input_enable, input_start, input_end, output_valid_n, output_start_n, output_end_n);
		start_1clk <= input_start;
		end_1clk <= input_end;

		if (input_enable) begin
			
			if (Coeff != 0) begin
				if ((previousRun == 0) || (previousRun == 1)) begin
					if (run < 3) begin
//						is_expo_golomb_code <= 2'b0;//1clk
						rice_golomb_code_valid <= input_enable;
						exp_golomb_code_valid <= 1'b0;
						is_add_setbit<=2'h0;
						k <= 0;//1clk
						run_n <= run;//1clk
						q = run;

					end else begin
//						is_expo_golomb_code <= 2'b1;
						rice_golomb_code_valid <= 1'b0;
						exp_golomb_code_valid <= input_enable;

						is_add_setbit<=2'h3;
						k <= 1;
						run_n <= run - 3;
					end
				end else if ((previousRun == 2) || (previousRun == 3)) begin
					if (run < 2) begin
//						is_expo_golomb_code <= 2'b0;
						rice_golomb_code_valid <= input_enable;
						exp_golomb_code_valid <= 1'b0;


						is_add_setbit<=2'h0;
						k <= 0;
						run_n <= run;
						q = run;

					end else begin
//						is_expo_golomb_code <= 2'b1;
						rice_golomb_code_valid <= 1'b0;
						exp_golomb_code_valid <= input_enable;

						is_add_setbit<=2'h2;
						k <= 1;
						run_n <= run - 2;
					end
				end else if ((previousRun == 4)) begin
//					is_expo_golomb_code <= 2'b1;
					rice_golomb_code_valid <= 1'b0;
					exp_golomb_code_valid <= input_enable;


					is_add_setbit <= 2'h0;
					k <= 0;
					run_n <= run;
				end else if ((previousRun >= 5) && (previousRun <= 8)) begin
					if (run < 4) begin
//						is_expo_golomb_code <= 2'b0;
						rice_golomb_code_valid <= input_enable;
						exp_golomb_code_valid <= 1'b0;


						is_add_setbit<=2'h0;
						k <= 1;
						run_n <= run;
						q = run>>1;

					end else begin
//						is_expo_golomb_code <= 2'b1;
						rice_golomb_code_valid <= 1'b0;
						exp_golomb_code_valid <= input_enable;



						is_add_setbit<=2'h2;
						k <= 2;
						run_n <= run - 4;
					end
				end else if ((previousRun >= 9) && (previousRun <= 14)) begin
//					is_expo_golomb_code <= 2'b1;
					rice_golomb_code_valid <= 1'b0;
					exp_golomb_code_valid <= input_enable;


					is_add_setbit <= 2'h0;
					k <= 1;
					run_n <= run;
				end else begin
//					is_expo_golomb_code <= 2'b1;
					rice_golomb_code_valid <= 1'b0;
					exp_golomb_code_valid <= input_enable;


					is_add_setbit <= 2'h0;
					k <= 2;
					run_n <= run;
				end
				previousRun <= run;
				run <= 0;
			end else begin
				run <= run + 1;
//				is_expo_golomb_code <= 2'b10;
				rice_golomb_code_valid <= 1'b0;
				exp_golomb_code_valid <= 1'b0;


			end
		end else begin
			rice_golomb_code_valid <= 1'b0;
			exp_golomb_code_valid <= 1'b0;
		end
	end
end




wire rice_output_valid;
wire exp_output_valid;


wire exp_output_start;
wire exp_output_end;

wire rice_output_start;
wire rice_output_end;

exp_golomb_code exp_golomb_code_inst(
	.reset_n(reset_n),
	.clk(clk),

	.input_start(start_1clk),
	.input_end(end_1clk),
	.input_valid(exp_golomb_code_valid),
	.val(run_n),
	.is_add_setbit(is_add_setbit),
	.k(k),
	.is_ac_level(0),
	.is_ac_minus_n(0),

	//output
	.output_valid(exp_output_valid),
	.output_start(exp_output_start),
	.output_end(exp_output_end),
	.sum_n(exp_golomb_sum),
	.codeword_length(exp_golomb_codeword_length)//3clk



);







golomb_rice_code golomb_rice_code_inst(
	.reset_n(reset_n),
	.clk(clk),


	.input_start(start_1clk),
	.input_end(end_1clk),
	.input_valid(rice_golomb_code_valid),
	.k(k),
	.val(run_n),
	.is_ac_level(0),
	.is_minus_n(0),
	
	//output
	.output_valid(rice_output_valid),
	.output_start(rice_output_start),
	.output_end(rice_output_end),

	.sum_n(rice_sum),
	.codeword_length(rice_codeword_length)


);



reg output_valid;
reg output_start;
reg output_end;

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		sum_n_n <= 0;
		codeword_length_n_n <= 0;
		output_valid <= 1'b0;
		output_start <= 1'b0;
		output_end <= 1'b0;
	end else begin
		if (rice_output_valid == 1'b1) begin
			sum_n_n <= rice_sum;
			codeword_length_n_n <= rice_codeword_length;
			output_valid <= 1'b1;
		end else if (exp_output_valid == 1'b1) begin
			sum_n_n <= exp_golomb_sum;
			output_valid <= 1'b1;
			codeword_length_n_n <= exp_golomb_codeword_length;//4clk
		end else  begin
			sum_n_n <= 0;
			codeword_length_n_n <= 0;
			output_valid <= 1'b0;
		end
		output_start <= exp_output_start|rice_output_start;
		output_end <= exp_output_end|rice_output_end;
	end
end


//levelに合わせるために、1CLK使用する
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		codeword_length_n_n_n <= 0;
		sum_n_n_n <= 0;
		output_valid_n <= 0;
		output_start_n <= 0;
		output_end_n <= 0;
	end else begin
		sum_n_n_n <= sum_n_n;
		codeword_length_n_n_n <= codeword_length_n_n;//5clk
		output_valid_n <= output_valid;
		output_start_n <= output_start;
		output_end_n <= output_end;
	//	$display("run %d", output_valid_n);
	end
end




endmodule
