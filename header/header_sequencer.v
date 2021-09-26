module header_sequencer(
	input wire clock,
	input wire  reset_n,

	input wire [31:0] slice_num,
	input wire [31:0] set_bit_total_byte_size,


output reg header_reset_n,
output reg matrix_reset_n,
output reg picture_header_reset_n,
output reg slice_size_table_reset_n,
output reg slice_header_reset_n,

	output reg [31:0]		slice_size_table_size,
	output reg [31:0] slice_size_offset_addr,
	output reg [31:0] picture_size_offset_addr,
	output reg [31:0] frame_size_offset_addr,
	output reg [31:0] y_size_offset_addr,
	output reg [31:0] cb_size_offset_addr

/*
	output reg [31:0] offset_addr,
	output reg [31:0] val,
	output reg [31:0] byte_size
*/

);

reg [31:0] counter;

always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		counter <= 32'h0;
	end else begin
		counter <= counter + 32'h1;
	end
end

reg [31:0]		header_size;
reg [31:0]		matrix_size;
reg [31:0]		picture_header_size;
reg [31:0]		slice_header_size;


always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		frame_size_offset_addr <= 32'h0;
	end else begin
		if (counter == 32'h0) begin
			//$display("aa");
			header_reset_n <= 1'b1;
		end else if (counter == 32'h20) begin 
			//$display("bb");
			header_reset_n <= 1'b0;

			matrix_reset_n <= 1'b1;
		end else if (counter == 32'h21) begin 
			header_size <=  set_bit_total_byte_size;
		end else if (counter == 32'hb0) begin 
//			$display(" header_size %x %d", header_size, header_size );
			matrix_reset_n <= 1'b0;
			picture_header_reset_n <= 1'b1;
		end else if (counter == 32'hb1) begin 
			matrix_size <=  set_bit_total_byte_size;
			picture_size_offset_addr <= set_bit_total_byte_size + 1;
			//$display("set_bit_total_byte_size %d", set_bit_total_byte_size);

		end else if (counter == 32'hc0) begin 
//			$display(" matrix_size %x %d", matrix_size, matrix_size );
			picture_header_reset_n <= 1'b0;
			slice_size_table_reset_n<=1'b1;
		end else if (counter == 32'hc1) begin 
			picture_header_size <=  set_bit_total_byte_size;
			slice_size_offset_addr <= set_bit_total_byte_size;
 		end else if (counter == (32'hc0 + slice_num+1)) begin
//		end else if (counter == (32'hc2)) begin
//			$display(" picture_header_size %x %d", picture_header_size, picture_header_size );
			slice_size_table_reset_n <= 1'b0;

			slice_header_reset_n<= 1'b1;
//			$display("%d", slice_num);
		end else if (counter == (32'hc0 + slice_num+2)) begin
			slice_size_table_size <=  set_bit_total_byte_size;
			//$display("slice_size_table_size %d", slice_size_table_size);
			y_size_offset_addr <= set_bit_total_byte_size + 2;
			cb_size_offset_addr <= set_bit_total_byte_size + 4;

//	
		end else if (counter == 32'hc0 + slice_num + 32'h10) begin
//			$display(" slice_size_table_size %x %d", slice_size_table_size, slice_size_table_size );
			slice_header_reset_n<= 1'b0;

		end else if (counter == 32'hc0 + slice_num + 32'h11) begin
			slice_header_size <=  set_bit_total_byte_size;

			//slice_size_tmp <= set_bit_total_byte_size - slice_size_table_size;
//			//slice数が多くなったら注意

		end
	end
end


endmodule;

