module header (
	input wire clock,
	input wire reset_n,

	input wire [15:0] horizontal,
	input wire [15:0] vertical,
	input wire [1:0]  chroma_format,
	input wire [1:0]  interlace_mode,
	input wire [3:0]  aspect_ratio_information,
	input wire [3:0]  frame_rate_code,
	input wire [7:0]  color_primaries,
	input wire [7:0]  transfer_characteristic,
	input wire [7:0]  matrix_coefficients,
	input wire [3:0]  alpha_channel_type,
	input wire [31:0] Y_QMAT[8][8],
	input wire [31:0] C_QMAT[8][8],
	input wire [31:0] QSCALE,

	input wire [31:0] slice_size_table_slice_num,

	input wire [31:0] set_bit_total_byte_size,

	output wire sb_reset,
	output wire sb_enable,
	output wire [63:0] sb_val,
	output wire [63:0] sb_size_of_bit,
	output wire sb_flush,

	output wire [31:0] slice_size_table_size,
	output wire [31:0] slice_size_offset_addr,
	output wire [31:0] picture_size_offset_addr,
	output wire [31:0] frame_size_offset_addr,
	output wire [31:0] y_size_offset_addr,
	output wire [31:0] cb_size_offset_addr


);


wire header_reset_n;
wire matrix_reset_n;
wire picture_header_reset_n;
wire slice_size_table_reset_n;
wire slice_header_reset_n;

header_sequencer header_sequencer_inst (
	.clock(clock),
	.reset_n(reset_n),

	.slice_num(slice_size_table_slice_num),
	.set_bit_total_byte_size(set_bit_total_byte_size),


	.header_reset_n(header_reset_n),
	.matrix_reset_n(matrix_reset_n),
	.picture_header_reset_n(picture_header_reset_n),
	.slice_size_table_reset_n(slice_size_table_reset_n),
	.slice_header_reset_n(slice_header_reset_n),

	.slice_size_table_size(slice_size_table_size),
	.slice_size_offset_addr(slice_size_offset_addr),
	.picture_size_offset_addr(picture_size_offset_addr),
	.frame_size_offset_addr(frame_size_offset_addr),
	.y_size_offset_addr(y_size_offset_addr),
	.cb_size_offset_addr(cb_size_offset_addr)


);



wire header_output_enable;
wire [63:0] header_val;
wire [63:0] header_size_of_bit;
wire header_flush;


frame_header frame_header_inst(
	.clock(clock),
	.reset_n(header_reset_n),


	//input
	.horizontal(horizontal),
	.vertical(vertical),
	.chroma_format(chroma_format),
	.interlace_mode(interlace_mode),
	.aspect_ratio_information(aspect_ratio_information),
	.frame_rate_code(frame_rate_code),
	.color_primaries(color_primaries),
	.transfer_characteristic(transfer_characteristic),
	.matrix_coefficients(matrix_coefficients),
	.alpha_channel_type(alpha_channel_type),
	.Y_QMAT(Y_QMAT),
	.C_QMAT(C_QMAT),


	//output
	.output_enable(header_output_enable),
	.val(header_val),
	.size_of_bit(header_size_of_bit),
	.flush_bit(header_flush)

);

wire matrix_output_enable;
wire [63:0] matrix_val;
wire [63:0] matrix_size_of_bit;
wire matrix_flush;

matrix matrix_inst (
	.clock(clock),
	.reset_n(matrix_reset_n),

	.Y_QMAT(Y_QMAT),
	.C_QMAT(C_QMAT),
	
	.output_enable(matrix_output_enable),
	.val(matrix_val),
	.size_of_bit(matrix_size_of_bit),
	.flush_bit(matrix_flush),

);

wire  picture_header_output_enable;
wire [63:0] picture_header_val;
wire [63:0] picture_header_size_of_bit;
wire picture_header_flush;

picture_header picture_header_inst (
	.clock(clock),
	.reset_n(picture_header_reset_n),

	//output
	.output_enable(picture_header_output_enable),
	.val(picture_header_val),
	.size_of_bit(picture_header_size_of_bit),
	.flush_bit(picture_header_flush),

);


wire slice_size_table_output_enable;
wire [63:0] slice_size_table_val;
wire [63:0] slice_size_table_size_of_bit;
wire slice_size_table_flush;


slice_size_table slice_size_table_inst (
	.clock(clock),
	.reset_n(slice_size_table_reset_n),

	//input
	.slice_num(slice_size_table_slice_num),


	//output
	.output_enable(slice_size_table_output_enable),
	.val(slice_size_table_val),
	.size_of_bit(slice_size_table_size_of_bit),
	.flush_bit(slice_size_table_flush),

);


wire slice_header_output_enable;
wire [63:0] slice_header_val;
wire [63:0] slice_header_size_of_bit;
wire slice_header_flush;

slice_header slice_header_inst (
	.clock(clock),
	.reset_n(slice_header_reset_n),

	//input
	.qscale(QSCALE),


	//output
	.output_enable(slice_header_output_enable),
	.val(slice_header_val),
	.size_of_bit(slice_header_size_of_bit),
	.flush_bit(slice_header_flush),

);



assign sb_reset =  picture_header_reset_n
					|matrix_reset_n
					|header_reset_n
					|slice_size_table_reset_n
					|slice_header_reset_n;

assign sb_enable =
					header_output_enable
					|matrix_output_enable
					|picture_header_output_enable
					|slice_size_table_output_enable
					|slice_header_output_enable;

assign sb_val = 
					header_val
					|matrix_val
					|picture_header_val
					|slice_size_table_val
					|slice_header_val;




assign sb_size_of_bit = header_size_of_bit
						|matrix_size_of_bit
						|picture_header_size_of_bit
						|slice_size_table_size_of_bit
						|slice_header_size_of_bit;

assign sb_flush = 
						header_flush
						|matrix_flush
						|picture_header_flush
						|slice_size_table_flush
						|slice_header_flush;



endmodule;