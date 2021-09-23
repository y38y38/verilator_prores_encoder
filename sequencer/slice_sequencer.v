module slice_sequencer (
	input clock,
	input reset_n,
	input wire [31:0] set_bit_total_byte_size,

	output reg header_reset_n,
	output reg matrix_reset_n,
	output reg picture_header_reset_n,
	output reg component_reset_n,
	output reg [31:0] counter,
	output reg [31:0] offset,
	output reg [31:0] block_num,
	output reg is_y,
	output reg [31:0] y_size,
	output reg [31:0] cb_size

//	input [31:0]input_mem[4096],
//	output [31:0]output_mem[2048]

);

reg [31:0] sequence_component = 0;

always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		counter <= 32'h0;
	end else begin
		counter <= counter + 32'h1;
	end
end

//localparam  COMPONENT_Y_TIME = 10000;
localparam  HEADER_TIME = 200;
localparam  COMPONENT_Y_TIME = 3000;
localparam  COMPONENT_C_TIME = 1500;


always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		component_reset_n <= 1'b0;
		header_reset_n <= 1'b0;
		matrix_reset_n <= 1'b0;
		picture_header_reset_n <= 1'b0;

		offset <= 32'h0;
		is_y <= 1'b1;
		y_size <= 32'h0;
		cb_size <= 32'h0;
		block_num <= 32'd32;
	end else begin
		if (counter == 32'h0) begin
			header_reset_n <= 1'b1;
		end else if (counter == 32'h20) begin 
			header_reset_n <= 1'b0;
			matrix_reset_n <= 1'b1;
		end else if (counter == 32'hb0) begin 
			matrix_reset_n <= 1'b0;
			picture_header_reset_n <= 1'b1;
		end else if (counter == 32'hc0) begin 
			picture_header_reset_n <= 1'b0;
		end else if (counter == HEADER_TIME) begin 
			component_reset_n <= 1'b1;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME) begin 
			component_reset_n <= 1'b0;
			offset <= 32'd2048;
			is_y <= 1'b0;
			y_size <= set_bit_total_byte_size;
			block_num <= 32'd16;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1) begin 
			component_reset_n <= 1'b1;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME) begin 
			component_reset_n <= 1'b0;
			offset <= 32'd3072;
			cb_size <= set_bit_total_byte_size;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME + 32'h1 ) begin 
			component_reset_n <= 1'b1;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME + 32'h1 + COMPONENT_C_TIME) begin 
			component_reset_n <= 1'b0;
		end

	end
end






endmodule;
