module entropy_encode_ac_run_coefficients(
	input clk,
	input reset_n,

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	input [31:0] Coeff,
	output reg [31:0] output_enable,//mask
	output reg [31:0] sum,
	output reg [31:0] sum_n,
	output reg [31:0] sum_n_n,
	output reg [31:0] sum_n_n_n,
	output reg [31:0] codeword_length,
	output reg [31:0] codeword_length_n,
	output reg [31:0] codeword_length_n_n,
	output reg [31:0] codeword_length_n_n_n,

	output reg [31:0] previousRun,
output reg signed [31:0] run,
output reg signed [31:0] run_n,
output reg [1:0] is_expo_golomb_code,
output reg [1:0] is_expo_golomb_code_n,
output reg [1:0] is_expo_golomb_code_n_n,
output reg [1:0] is_add_setbit,
output reg [2:0] k,

output wire [31:0] exp_golomb_sum,
output wire [31:0] exp_golomb_codeword_length,
output wire [31:0] rice_sum,
output wire [31:0] rice_codeword_length,

output wire is_minus_n_n_tmp,
output wire is_ac_level_n_tmp,
output wire [31:0] q_tmp2,
output wire [2:0] k_n_tmp2,
output wire [31:0] sum_tmp2,

output reg [31:0] q



);


/*
function [31:0] getabs;
	input [31:0] value;
	begin
		if (value[31] != 1'b1) begin
			getabs = value;
		end else begin
			getabs =  (~(value - 1));
		end
	end
endfunction


function [31:0] getfloorclog2;
	input [31:0] val;
	begin
		reg [31:0] in_val;
		in_val = val;
		for (getfloorclog2=0; in_val>0; getfloorclog2=getfloorclog2+1) begin
			in_val = in_val>>1;
		end
		getfloorclog2 = getfloorclog2 - 1;
	end
endfunction



function [31:0] bitmask;
	input [31:0] val;
	reg [31:0] index = 6'h0;
	begin
		bitmask = 32'h1;
		for(index=1;index<val;index=index+1) begin
			bitmask = (bitmask<<1) | 1;
		end
	end
endfunction

*/


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
//					run_n <= 100;
					run_n <= run;//1clk
					q = run;

				end else begin
					is_expo_golomb_code <= 2'b1;
					is_add_setbit<=2'h3;
					k <= 1;
//					run_n <= 100;
					run_n <= run - 3;
//run_n <= -4;
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





//assign LENGTH = codeword_length;


//reg [31:0] codeword_length = 32'h0;
/*
//exp_golomb_code
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		output_enable = 32'h0;
		sum = 32'h0;
	end else begin
		if (is_expo_golomb_code == 2'b1) begin
			q = getfloorclog2((run_n + (1<<(k)))) - k;
			sum[31:0] = run_n + (1<<k);
			codeword_length = (2 * q) + k + 1 + is_add_setbit;
		end
	end
end
*/






wire [31:0] sum_tmp;
wire [31:0] q_tmp;
wire [1:0] is_add_setbit_n_tmp;
wire [2:0] k_n_tmp;

exp_golomb_code exp_golomb_code_inst(
	.reset_n(reset_n),
	.clk(clk),
	.val(run_n),
	.is_add_setbit(is_add_setbit),
	.k(k),
	.is_ac_level(0),
	.is_ac_minus_n(0),
	.sum_n(exp_golomb_sum),
	.codeword_length(exp_golomb_codeword_length),//3clk
	.sum(sum_tmp),
	.q(q_tmp),
	.is_add_setbit_n(is_add_setbit_n_tmp),
	.k_n(k_n_tmp)

);






/*
//golomb_rice_code
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		output_enable = 32'h0;
		sum = 32'h0;
		codeword_length = 32'h0;
	end else begin
		if (is_expo_golomb_code == 2'b0) begin
			//q=と、if(qのタイミング)
//			q = run_n >> k;
			if (k==0) begin
				if(q!=0) begin
					sum = 1;
					codeword_length = q+1;
//					output_enable = bitmask(codeword_length);
				end else begin
					sum = 1;
					codeword_length = 1;
					output_enable = 1;
				end
			end else begin
				// 0x4 | 1 & 0x3
				// 0x5 
				sum = (1<<k) | (run_n & ((1<<k) - 1));
//				sum = 20'h111 ;//(1<<k) | (run_n & ((1<<k) - 1));
				codeword_length = q + 1 + k;
//				output_enable = bitmask( codeword_length);	
			end
		end
	end
end
*/



golomb_rice_code golomb_rice_code_inst(
	.reset_n(reset_n),
	.clk(clk),
	.k(k),
	.val(run_n),
	.is_ac_level(0),
	.is_minus_n(0),
	.sum_n(rice_sum),
	.codeword_length(rice_codeword_length),
//	.k_n(k_n),
//	.sum(sum)
	.is_minus_n_n(is_minus_n_n_tmp),
	.is_ac_level_n(is_ac_level_n_tmp),
	.q(q_tmp2),
	.k_n(k_n_tmp2),
	.sum(sum_tmp2)

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
//		codeword_length_n <= 0;
//		sum_n <= 0;
	end else begin
//		sum_n <= sum;
//		codeword_length_n <= codeword_length;
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
//			sum_n_n <= sum_n;
//			codeword_length_n_n <= codeword_length_n;
		end else if (is_expo_golomb_code_n_n == 2'b01) begin
			sum_n_n <= exp_golomb_sum;
			codeword_length_n_n <= exp_golomb_codeword_length;//4clk
//			sum_n_n <= sum_n;
//			codeword_length_n_n <= codeword_length_n;
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
			output_enable = 0;
		end
	end
end



endmodule;
