module sequencer (
	input clock,
	input reset_n,
	input wire [31:0] set_bit_total_byte_size,
	input wire [31:0] slice_num,

	input wire [31:0] slice_size_table_size,

	input wire [31:0] slice_size_offset_addr,
	input wire [31:0] picture_size_offset_addr,
	input wire [31:0] frame_size_offset_addr,
	input wire [31:0] y_size_offset_addr,
	input wire [31:0] cb_size_offset_addr,





	output reg header2_reset_n,
	output reg component_reset_n,
	output reg [31:0] counter,
	output reg [31:0] offset,
	output reg [31:0] block_num,
	output reg is_y,

	output reg [31:0] offset_addr,
	output reg [31:0] val,
	output reg [31:0] byte_size




	

);

reg [31:0] picture_size;
reg [31:0] frame_size;
reg [31:0] slice_size;
reg [31:0] slice_size_tmp;
reg [31:0] y_size;
reg [31:0] cb_size;
reg [31:0] cr_size;



reg [31:0] sequence_component = 0;

always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		counter <= 32'h0;
	end else begin
		counter <= counter + 32'h1;
	end
end

//localparam  COMPONENT_Y_TIME = 10000;
localparam  HEADER_TIME = 32'he0;
localparam  COMPONENT_Y_TIME = 2400;
localparam  COMPONENT_C_TIME = 1200;



always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		component_reset_n <= 1'b0;


		offset <= 32'h0;
		is_y <= 1'b1;
		y_size <= 32'h0;
		cb_size <= 32'h0;
		cr_size <= 32'h0;
		block_num <= 32'd32;

//		slice_top <= 32'h0;
		slice_size <= 32'h0;
		slice_size_tmp <= 32'h0;

		picture_size <= 32'h0;
		frame_size <= 32'h0;

		header2_reset_n <= 1'b0;
	end else begin
		if (counter == 32'h0) begin
			header2_reset_n <= 1'b1;
		end else if (counter == 32'hc0 + slice_num + 32'h10) begin
			header2_reset_n <= 1'b0;

		end else if (counter == 32'hc0 + slice_num + 32'h11) begin
			slice_size_tmp <= set_bit_total_byte_size - slice_size_table_size;
		end else if (counter == HEADER_TIME) begin 
			
			component_reset_n <= 1'b1;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME) begin 
//			//$display(" slicetop %x %x", slice_top,set_bit_total_byte_size );
			component_reset_n <= 1'b0;
			offset <= 32'd2048;
			is_y <= 1'b0;
			y_size <= set_bit_total_byte_size;
			slice_size_tmp <= slice_size_tmp + set_bit_total_byte_size;
			//$display("1 %d", slice_size_tmp);
			block_num <= 32'd16;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1) begin 
			component_reset_n <= 1'b1;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME) begin 
			component_reset_n <= 1'b0;
			offset <= 32'd3072;
			cb_size <= set_bit_total_byte_size;
			slice_size_tmp <= slice_size_tmp + set_bit_total_byte_size;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME + 32'h1 ) begin 
			component_reset_n <= 1'b1;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME + 32'h1 + COMPONENT_C_TIME) begin 
			component_reset_n <= 1'b0;
			cr_size <= set_bit_total_byte_size;
			slice_size_tmp <= slice_size_tmp + set_bit_total_byte_size;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME + 32'h1 + COMPONENT_C_TIME + 1) begin 
			slice_size <= slice_size_tmp;


			picture_size <= slice_size_tmp + slice_size_table_size - picture_size_offset_addr +1;
			frame_size <= slice_size_tmp + slice_size_table_size;
		end

	end
end


always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
			offset_addr <= 32'h0;
			val <= 32'h0;
			byte_size <= 32'h0;
	end else begin
		if (slice_size>0) begin
			offset_addr <= slice_size_offset_addr;
			val <= slice_size;
			byte_size <= 32'h2;
			slice_size <= 32'h0;
		end else if (picture_size>0) begin
			offset_addr <= picture_size_offset_addr;
			val <= picture_size;
			byte_size <= 32'h4;
			picture_size <= 32'h0;
		end else if (frame_size>0) begin
			offset_addr <= frame_size_offset_addr;
			val <= frame_size;
		//	$display("frame_size %d", frame_size);
			byte_size <= 32'h4;
			frame_size <= 32'h0;
		end else if (y_size>0) begin
			offset_addr <= y_size_offset_addr;
			val <= y_size;
			byte_size <= 32'h2;
			y_size <= 32'h0;

		end else if (cb_size>0) begin
			offset_addr <= cb_size_offset_addr;
			val <= cb_size;
			byte_size <= 32'h2;
			cb_size <= 32'h0;

		end	else begin
			offset_addr <= 32'h0;
			val <= 32'h0;
			byte_size <= 32'h0;
		end
	end
end





endmodule;
