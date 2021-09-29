module component(
	input wire clock,
	input wire component_reset_n,

	//input
	input wire [31:0] slice_sequencer_block_num,
	input wire [31:0]slice_sequencer_offset,
	input wire [31:0] INPUT_DATA_MEM[4096],

	input wire is_y,
	input wire [31:0] QSCALE,
	input wire [31:0] Y_QMAT[8][8],
	input wire [31:0] C_QMAT[8][8],


	//output
//	output wire sb_reset,
	output wire sb_enable,
	output wire [63:0] sb_val,
	output wire [63:0] sb_size_of_bit,
	output wire sb_flush

);

wire [31:0] sequence_counter;
wire [31:0] sequence_counter2;
wire [31:0] dc_vlc_counter;
wire [31:0] ac_vlc_counter;
wire dc_vlc_reset;
wire dc_vlc_output_enable;
wire ac_vlc_reset;


wire [31:0] INPUT_DATA_ARRAY2[8][8];
wire [31:0] PRE_DCT_OUTPUT[8][8];
wire [31:0] DCT_OUTPUT[8][8];
wire [31:0] OUTPUT_DATA[8][8];
wire [31:0] v_data_result[2048];


wire [31:0] INPUT_DC_DATA2;

wire [31:0] DC_BITSTREAM_SUM;
wire [31:0] LENGTH;


wire [31:0] INPUT_AC_DATA2;

wire [31:0] AC_BITSTREAM_LEVEL_LENGTH;
wire [31:0] AC_BITSTREAM_LEVEL_SUM;

wire [31:0] AC_BITSTREAM_RUN_LENGTH;
wire [31:0] AC_BITSTREAM_RUN_SUM;




wire dc_output_enable;
wire [63:0] dc_output_val;
wire [63:0]  dc_output_size_of_bit;
wire dc_output_flush;
wire ac_output_enable;
wire [63:0] ac_output_val;
wire [63:0] ac_output_size_of_bit;
wire ac_vlc_output_flush;
wire ac_output_flush;
wire ac_vlc_output_enable;


component_sequencer component_sequencer_inst(
	.clock(clock),
	.reset_n(component_reset_n),

	//input
	.block_num(slice_sequencer_block_num),


	//output
 	.sequence_counter(sequence_counter),
	.dc_vlc_reset(dc_vlc_reset),
	.dc_vlc_output_enable(dc_vlc_output_enable),
	.dc_vlc_counter(dc_vlc_counter),

	.ac_vlc_reset(ac_vlc_reset),
	.ac_vlc_output_enable(ac_vlc_output_enable),
	.ac_vlc_output_flush(ac_vlc_output_flush),
	.ac_vlc_counter(ac_vlc_counter),
	.sequence_counter2(sequence_counter2)

);
//wire [31:0] PRE_DCT_OUTPUT[8][8];

array_from_mem array_form_mem_inst (
	.clock(clock),
	.reset_n(component_reset_n),

	//input
	.counter(sequence_counter),
	.input_data(INPUT_DATA_MEM),
	.offset(slice_sequencer_offset),


	//output
	.output_data_array(INPUT_DATA_ARRAY2)
);

pre_dct pre_dct_inst (
	.CLOCK(clock),
	.RESET(component_reset_n),

	//input
	.INPUT_DATA(INPUT_DATA_ARRAY2),

	//output
	.OUTPUT_DATA(PRE_DCT_OUTPUT)
);


//wire [31:0] DCT_OUTPUT[8][8];

dct dct_inst (
	.CLOCK(clock),
	.RESET(component_reset_n),

	//input
	.INPUT_DATA(PRE_DCT_OUTPUT),

	//output
	.OUTPUT_DATA(DCT_OUTPUT)
    );


pre_quant_qt_qscale pre_quant_qt_qscale_inst(
	.CLOCK(clock),
	.RESET(component_reset_n),

	//input
	.INPUT_DATA(DCT_OUTPUT),
	.QSCALE(QSCALE),
	.is_y(is_y),
	.Y_QMAT(Y_QMAT),
	.C_QMAT(C_QMAT),

	//output
	.OUTPUT_DATA(OUTPUT_DATA)

);

array_to_mem array_to_mem_inst(
	.clock(clock),
	.reset_n(component_reset_n),

	//input
	.counter(sequence_counter2),
	.input_data_array(OUTPUT_DATA),
	
	//output
	.output_data(v_data_result)

);

mem_to_dc_vlc mem_to_dc_vlc_inst(
	.clock(clock),
	.reset_n(component_reset_n),
	.counter(dc_vlc_counter),

	//input
	.block_num(slice_sequencer_block_num),
	.input_data(v_data_result),

	//output
	.vlc_dc(INPUT_DC_DATA2)
);

mem_to_ac_vlc mem_to_ac_vlc_inst(
	.clock(clock),
	.reset_n(component_reset_n),

	//input
	.counter(ac_vlc_counter),
	.block_num(slice_sequencer_block_num),
	.input_data(v_data_result),

	//output
	.vlc_ac(INPUT_AC_DATA2)

);


entropy_encode_dc_coefficients entropy_encode_dc_coefficients_inst(
	.clk(clock),
	.reset_n(dc_vlc_reset),
	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	.DcCoeff(INPUT_DC_DATA2),
	.sum_n_n(DC_BITSTREAM_SUM),
	.codeword_length_n(LENGTH)


);

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


dc_output dc_output_inst(
	.clock(clock),
	.reset_n(dc_vlc_reset),

	//input
	.LENGTH(LENGTH),
	.SUM(DC_BITSTREAM_SUM),
	.enable(dc_vlc_output_enable),

	//output
	.output_enable(dc_output_enable),
	.val(dc_output_val),
	.size_of_bit(dc_output_size_of_bit),
	.flush_bit(dc_output_flush)
);


ac_output ac_output_inst(
	.clock(clock),
	.reset_n(ac_vlc_reset),
	

	//input
	.RUN_LENGTH(AC_BITSTREAM_RUN_LENGTH),
	.RUN_SUM(AC_BITSTREAM_RUN_SUM),
	.LEVEL_LENGTH(AC_BITSTREAM_LEVEL_LENGTH),
	.LEVEL_SUM(AC_BITSTREAM_LEVEL_SUM),
	.enable(ac_vlc_output_enable),
	.ac_vlc_output_flush(ac_vlc_output_flush),

	//output
	.output_enable(ac_output_enable),
	.val(ac_output_val),
	.size_of_bit(ac_output_size_of_bit),
	.flush_bit(ac_output_flush)
);

//assign sb_reset = component_reset_n ;

assign sb_enable = dc_output_enable
					|ac_output_enable;

assign sb_val = dc_output_val
					|ac_output_val;


assign sb_size_of_bit = dc_output_size_of_bit
						|ac_output_size_of_bit;

assign sb_flush = dc_output_flush
						|ac_output_flush;


endmodule;

