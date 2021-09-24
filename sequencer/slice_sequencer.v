module slice_sequencer (
	input clock,
	input reset_n,
	input wire [31:0] set_bit_total_byte_size,
	input wire [31:0] slice_num,

	output reg header_reset_n,
	output reg matrix_reset_n,
	output reg picture_header_reset_n,
	output reg slice_size_table_reset_n,
	output reg slice_header_reset_n,
	output reg component_reset_n,
	output reg [31:0] counter,
	output reg [31:0] offset,
	output reg [31:0] block_num,
	output reg is_y,
	output reg [31:0] slice_top,
	output reg [31:0] slice_table_top,

	output reg [31:0] offset_addr,
	output reg [31:0] val,
	output reg [31:0] byte_size,
	
	output reg [31:0] picture_size,
	output reg [31:0] slice_size,
	output reg [31:0] slice_size_tmp,
	output reg [31:0] y_size,
	output reg [31:0] cb_size,
	output reg [31:0] cr_size


	
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
localparam  HEADER_TIME = 32'he0;
localparam  COMPONENT_Y_TIME = 3000;
localparam  COMPONENT_C_TIME = 1500;

reg [31:0]		header_size;
reg [31:0]		matrix_size;
reg [31:0]		picture_header_size;
reg [31:0]		slice_size_table_size;
reg [31:0]		slice_header_size;


always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		component_reset_n <= 1'b0;
		header_reset_n <= 1'b0;
		matrix_reset_n <= 1'b0;
		picture_header_reset_n <= 1'b0;
		slice_header_reset_n <= 1'b0;

		header_size <= 32'h0;
		matrix_size <= 32'h0;
		picture_header_size <=32'h0;
		slice_size_table_size <= 32'h0;
		slice_header_size <= 32'h0;

		offset <= 32'h0;
		is_y <= 1'b1;
		y_size <= 32'h0;
		cb_size <= 32'h0;
		cr_size <= 32'h0;
		block_num <= 32'd32;

		slice_top <= 32'h0;
		slice_size <= 32'h0;
		slice_size_tmp <= 32'h0;

		picture_size <= 32'h0;

	end else begin

		//total_byte_sizeはリセットをかけると、0になるので注意。
		//今はリセットなしで、Slice Headerまで走っている
		//サイズが確定するのは1clock後なのに注意
		if (counter == 32'h0) begin
			header_reset_n <= 1'b1;
		end else if (counter == 32'h20) begin 
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
		end else if (counter == 32'hc0) begin 
//			$display(" matrix_size %x %d", matrix_size, matrix_size );
			picture_header_reset_n <= 1'b0;
			slice_size_table_reset_n<=1'b1;
		end else if (counter == 32'hc1) begin 
			picture_header_size <=  set_bit_total_byte_size;

 		end else if (counter == (32'hc0 + slice_num+1)) begin
//		end else if (counter == (32'hc2)) begin
//			$display(" picture_header_size %x %d", picture_header_size, picture_header_size );
			slice_size_table_reset_n <= 1'b0;

			slice_header_reset_n<= 1'b1;
//			$display("%d", slice_num);
		end else if (counter == (32'hc0 + slice_num+2)) begin
			slice_size_table_size <=  set_bit_total_byte_size;
//
		end else if (counter == 32'hc0 + slice_num + 32'h10) begin
//			$display(" slice_size_table_size %x %d", slice_size_table_size, slice_size_table_size );
			slice_header_reset_n<= 1'b0;

		end else if (counter == 32'hc0 + slice_num + 32'h11) begin
			slice_header_size <=  set_bit_total_byte_size;

			slice_size_tmp <= set_bit_total_byte_size - slice_size_table_size;
//			//slice数が多くなったら注意

			//sbにリセットがはいる。
		end else if (counter == HEADER_TIME) begin 
			$display(" slice_header_size %x %d", slice_header_size, slice_header_size );
			component_reset_n <= 1'b1;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME) begin 
			$display(" slicetop %x %x", slice_top,set_bit_total_byte_size );
			component_reset_n <= 1'b0;
			offset <= 32'd2048;
			is_y <= 1'b0;
			y_size <= set_bit_total_byte_size;
			slice_size_tmp <= slice_size_tmp + set_bit_total_byte_size;
			$display("1 %d", slice_size_tmp);
			block_num <= 32'd16;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1) begin 
			component_reset_n <= 1'b1;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME) begin 
			component_reset_n <= 1'b0;
			offset <= 32'd3072;
			cb_size <= set_bit_total_byte_size;
			slice_size_tmp <= slice_size_tmp + set_bit_total_byte_size;
			$display("2 %d", slice_size_tmp);
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME + 32'h1 ) begin 
			component_reset_n <= 1'b1;
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME + 32'h1 + COMPONENT_C_TIME) begin 
			component_reset_n <= 1'b0;
			cr_size <= set_bit_total_byte_size;
			slice_size_tmp <= slice_size_tmp + set_bit_total_byte_size;
			$display("3 %d", slice_size_tmp);
		end else if (counter == HEADER_TIME + COMPONENT_Y_TIME + 32'h1 + COMPONENT_C_TIME + 32'h1 + COMPONENT_C_TIME + 1) begin 
			$display("size %d %d %d %d %d", slice_header_size-slice_size_table_size, y_size, cb_size, cr_size, (slice_header_size-slice_size_table_size)+y_size+ cb_size+ cr_size );
//			slice_size <= (slice_header_size-slice_size_table_size)+y_size+ cb_size+ cr_size ;
			slice_size <= slice_size_tmp;
			$display("4 %d", slice_size_tmp);


			picture_size <= slice_size_tmp + slice_size_table_size - matrix_size;
			$display("4p %x", slice_size_tmp + slice_size_table_size + picture_header_size);
		end

	end
end


always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
			offset_addr <= 32'h0;
			val <= 32'h0;
			byte_size <= 32'h0;
	end else begin
		if (slice_size) begin
			offset_addr <= picture_header_size;
			val <= slice_size;
			byte_size <= 32'h2;
			slice_size <= 32'h0;
		end else if (picture_size) begin
			offset_addr <= matrix_size + 1;
			val <= picture_size;
			byte_size <= 32'h4;
			picture_size <= 32'h0;
		end else if (y_size) begin
			offset_addr <= slice_size_table_size + 2;
			val <= y_size;
			byte_size <= 32'h2;
			y_size <= 32'h0;

		end else if (cb_size) begin
			offset_addr <= slice_size_table_size + 4;
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
