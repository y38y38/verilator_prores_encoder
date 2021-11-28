module ac_vlc(
	input wire clock,
	input wire reset_n,//0 reset , 1 not reset

	//input parameter
	input wire block_num,
	input wire is_y,

	//input 
	input wire input_enable,
	input wire [31:0]input_data,

	//output
	output wire output_enable,
	output wire  [63:0] val,
	output wire [63:0] size_of_bit,
	output wire flush_bit,
	output wire ac_vlc_end
);




reg [31:0] counter = 32'h0;

always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		counter <= 32'h0;
	end else begin
		if (input_enable) begin
			counter <= counter + 32'h1;
		end
	end
end



entropy_encode_ac_level_coefficients entropy_encode_ac_level_coefficients_inst(
	.clk(clock),
	.reset_n(ac_vlc_reset),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA2),


	.sum_n_n(AC_BITSTREAM_LEVEL_SUM),
	.codeword_length_n_n(AC_BITSTREAM_LEVEL_LENGTH)
);

entropy_encode_ac_run_coefficients entropy_encode_ac_run_coefficients_inst(
	.clk(clock),
	.reset_n(ac_vlc_reset),

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.Coeff(INPUT_AC_DATA2),


	.sum_n_n_n(AC_BITSTREAM_RUN_SUM),
	.codeword_length_n_n_n(AC_BITSTREAM_RUN_LENGTH)
);








