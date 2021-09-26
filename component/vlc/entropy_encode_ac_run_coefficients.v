module entropy_encode_ac_run_coefficients(
	input clk,
	input reset_n,

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	input [31:0] Coeff,

	output reg [31:0] sum_n_n_n,
	output reg [31:0] codeword_length_n_n_n



);

reg [31:0] sum;
reg [31:0] sum_n;
reg [31:0] sum_n_n;
reg [31:0] codeword_length;
reg [31:0] codeword_length_n;
reg [31:0] codeword_length_n_n;
reg [31:0] previousRun;
reg signed [31:0] run;
reg signed [31:0] run_n;
reg [1:0] is_expo_golomb_code;
reg [1:0] is_expo_golomb_code_n;
reg [1:0] is_expo_golomb_code_n_n;
reg [1:0] is_add_setbit;
reg [2:0] k;

wire [31:0] exp_golomb_sum;
wire [31:0] exp_golomb_codeword_length;
wire [31:0] rice_sum;
wire [31:0] rice_codeword_length;

reg [31:0] q;



always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		previousRun <= 32'h4;
		run <= 32'h0;
		is_expo_golomb_code <= 2'h2;

	end else begin
		if (Coeff != 0) begin
			if ((previousRun == 0) || (previousRun == 1)) begin
				if (run < 3) begin
					is_expo_golomb_code <= 2'b0;//1clk
					is_add_setbit<=2'h0;
					k <= 0;//1clk
					run_n <= run;//1clk
					q = run;

				end else begin
					is_expo_golomb_code <= 2'b1;
					is_add_setbit<=2'h3;
					k <= 1;
					run_n <= run - 3;
				end
			end else if ((previousRun == 2) || (previousRun == 3)) begin
				if (run < 2) begin
					is_expo_golomb_code <= 2'b0;
					is_add_setbit<=2'h0;
					k <= 0;
					run_n <= run;
					q = run;

				end else begin
					is_expo_golomb_code <= 2'b1;
					is_add_setbit<=2'h2;
					k <= 1;
					run_n <= run - 2;
				end
			end else if ((previousRun == 4)) begin
				is_expo_golomb_code <= 2'b1;
				is_add_setbit <= 2'h0;
				k <= 0;
				run_n <= run;
			end else if ((previousRun >= 5) && (previousRun <= 8)) begin
				if (run < 4) begin
					is_expo_golomb_code <= 2'b0;
					is_add_setbit<=2'h0;
					k <= 1;
					run_n <= run;
					q = run>>1;

				end else begin
					is_expo_golomb_code <= 2'b1;
					is_add_setbit<=2'h2;
					k <= 2;
					run_n <= run - 4;
				end
			end else if ((previousRun >= 9) && (previousRun <= 14)) begin
				is_expo_golomb_code <= 2'b1;
				is_add_setbit <= 2'h0;
				k <= 1;
				run_n <= run;
			end else begin
				is_expo_golomb_code <= 2'b1;
				is_add_setbit <= 2'h0;
				k <= 2;
				run_n <= run;
			end
			previousRun <= run;
			run <= 0;
		end else begin
			run <= run + 1;
			is_expo_golomb_code <= 2'b10;

		end

	end
end





exp_golomb_code exp_golomb_code_inst(
	.reset_n(reset_n),
	.clk(clk),
	.val(run_n),
	.is_add_setbit(is_add_setbit),
	.k(k),
	.is_ac_level(0),
	.is_ac_minus_n(0),

	//output
	.sum_n(exp_golomb_sum),
	.codeword_length(exp_golomb_codeword_length)//3clk



);







golomb_rice_code golomb_rice_code_inst(
	.reset_n(reset_n),
	.clk(clk),
	.k(k),
	.val(run_n),
	.is_ac_level(0),
	.is_minus_n(0),
	
	//output
	.sum_n(rice_sum),
	.codeword_length(rice_codeword_length)


);


always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_expo_golomb_code_n <= 2'b10;
		is_expo_golomb_code_n_n <= 2'b10;
	end else begin
		is_expo_golomb_code_n <= is_expo_golomb_code;
		is_expo_golomb_code_n_n <= is_expo_golomb_code_n;
	end
end


always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		sum_n_n <= 0;
		codeword_length_n_n <= 0;
	end else begin
		if (is_expo_golomb_code_n_n == 2'b00) begin
			sum_n_n <= rice_sum;
			codeword_length_n_n <= rice_codeword_length;
		end else if (is_expo_golomb_code_n_n == 2'b01) begin
			sum_n_n <= exp_golomb_sum;
			codeword_length_n_n <= exp_golomb_codeword_length;//4clk
		end else if (is_expo_golomb_code_n_n == 2'b10) begin
			sum_n_n <= 0;
			codeword_length_n_n <= 0;
		end
	end
end

//levelに合わせるために、1CLK使用する
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		codeword_length_n_n_n <= 0;
		sum_n_n_n <= 0;
	end else begin
		sum_n_n_n <= sum_n_n;
		codeword_length_n_n_n <= codeword_length_n_n;//5clk
	end
end



always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
	end else begin
		if (is_expo_golomb_code == 2'h2) begin
			sum = 0;
			codeword_length = 0;
		end
	end
end



endmodule;
