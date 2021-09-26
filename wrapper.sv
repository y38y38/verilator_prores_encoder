`timescale 1ns / 1ps

`include "prores_param.v"
`include "encoder_def.v"


module wapper(
	input wire CLOCK,
	input wire RESET,


	//input data
	input wire [31:0] INPUT_DATA_MEM[4096],

	//encode param
	input wire [31:0] QSCALE,
	input wire [31:0] Y_QMAT[8][8],
	input wire [31:0] C_QMAT[8][8],

	//parameter
	input wire [15:0]header_horizontal,
	input wire [15:0]header_vertical,
	input wire [1:0] header_chroma_format,
	input wire [1:0] header_interlace_mode,
	input wire [3:0] header_aspect_ratio_information,
	input wire [3:0] header_frame_rate_code,
	input wire [7:0] header_color_primaries,
	input wire [7:0] header_transfer_characteristic,
	input wire [7:0] header_matrix_coefficients,
	input wire [3:0] header_alpha_channel_type,

	//temporary
	input wire [31:0] slice_size_table_slice_num,
	input wire [31:0] block_num,


	//output
	output wire [3:0]  set_bit_output_enable_byte,
	output wire [63:0]  set_bit_output_val,

	output wire [31:0]	slice_sequencer_offset_addr,
	output wire [31:0]	slice_sequencer_val,
	output wire [31:0]	slice_sequencer_byte_size

    );



wire component_reset_n;
wire [31:0] slice_sequencer_counter;
wire [31:0] slice_sequencer_offset;
wire [31:0] slice_sequencer_block_num;
wire [31:0] set_bit_total_byte_size;
wire is_y;

wire header2_reset_n;

sequencer sequencer_inst(
	.clock(CLOCK),
	.reset_n(RESET),

	//input
	.set_bit_total_byte_size(set_bit_total_byte_size),
	.slice_num(slice_size_table_slice_num),


	.slice_size_table_size(slice_size_table_size),

	.slice_size_offset_addr(slice_size_offset_addr),
	.picture_size_offset_addr(picture_size_offset_addr),
	.frame_size_offset_addr(frame_size_offset_addr),
	.y_size_offset_addr(y_size_offset_addr),
	.cb_size_offset_addr(cb_size_offset_addr),



	//output
	.header2_reset_n(header2_reset_n),

	.component_reset_n(component_reset_n),
	.counter(slice_sequencer_counter),
	.offset(slice_sequencer_offset),
	.block_num(slice_sequencer_block_num),

	.is_y(is_y),

	.offset_addr(slice_sequencer_offset_addr),
	.val(slice_sequencer_val),
	.byte_size(slice_sequencer_byte_size)
	


);



wire [31:0] slice_size_table_size;
wire [31:0] slice_size_offset_addr;
wire [31:0] picture_size_offset_addr;
wire [31:0] frame_size_offset_addr;
wire [31:0] y_size_offset_addr;
wire [31:0] cb_size_offset_addr;

wire header_sb_reset;
wire header_sb_enable;
wire [63:0] header_sb_val;
wire [63:0] header_sb_size_of_bit;
wire header_sb_flush;

header header_inst(
	.clock(CLOCK),
	.reset_n(header2_reset_n),


	//input
	.horizontal(header_horizontal),
	.vertical(header_vertical),
	.chroma_format(header_chroma_format),
	.interlace_mode(header_interlace_mode),
	.aspect_ratio_information(header_aspect_ratio_information),
	.frame_rate_code(header_frame_rate_code),
	.color_primaries(header_color_primaries),
	.transfer_characteristic(header_transfer_characteristic),
	.matrix_coefficients(header_matrix_coefficients),
	.alpha_channel_type(header_alpha_channel_type),
	.Y_QMAT(Y_QMAT),
	.C_QMAT(C_QMAT),
	.QSCALE(QSCALE),

	.slice_size_table_slice_num(slice_size_table_slice_num),

	.set_bit_total_byte_size(set_bit_total_byte_size),

	.sb_reset(header_sb_reset),
	.sb_enable(header_sb_enable),
	.sb_val(header_sb_val),
	.sb_size_of_bit(header_sb_size_of_bit),
	.sb_flush(header_sb_flush),

	.slice_size_table_size(slice_size_table_size),
	.slice_size_offset_addr(slice_size_offset_addr),
	.picture_size_offset_addr(picture_size_offset_addr),
	.frame_size_offset_addr(frame_size_offset_addr),
	.y_size_offset_addr(y_size_offset_addr),
	.cb_size_offset_addr(cb_size_offset_addr)

);


wire component_enable;
wire [63:0] component_val;
wire [63:0] component_size_of_bit;
wire component_flush;

component component_inst(
	.clock(CLOCK),
	.component_reset_n(component_reset_n),
	.slice_sequencer_block_num(slice_sequencer_block_num),
	.slice_sequencer_offset(slice_sequencer_offset),
	.INPUT_DATA_MEM(INPUT_DATA_MEM),
	.is_y(is_y),
	.Y_QMAT(Y_QMAT),
	.C_QMAT(C_QMAT),
	.QSCALE(QSCALE),

//	.sb_reset(),
	.sb_enable(component_enable),
	.sb_val(component_val),
	.sb_size_of_bit(component_size_of_bit),
	.sb_flush(component_flush)

);




wire sb_reset;
wire sb_enable;
wire [63:0] sb_val;
wire [63:0] sb_size_of_bit;
wire sb_flush;

assign sb_reset = component_reset_n 
					|header2_reset_n;

assign sb_enable = 
				component_enable
					|header_sb_enable;

assign sb_val = 
				component_val
					|header_sb_val;




assign sb_size_of_bit = 
				component_size_of_bit
						|header_sb_size_of_bit;

assign sb_flush = 
				component_flush
						|header_sb_flush;


set_bit set_bit_inst(
	.clock(CLOCK),
	.reset_n(sb_reset),

	//input
	.enable(sb_enable),
	.val(sb_val),
	.size_of_bit(sb_size_of_bit),
	.flush_bit(sb_flush),//val, size_of_bitを参照せずに、bitを吐き出す。

	//output
	.output_enable_byte(set_bit_output_enable_byte),
	.output_val(set_bit_output_val),
	.total_byte_size(set_bit_total_byte_size)
	
);


endmodule;



