
`include "encoder_config.v"


//8bit以上溜まったら送信する
module set_bit(
	input clock,
	input reset_n,
	input enable,
	input [63:0] val,
	input [63:0] size_of_bit,
	input flush_bit,//val, size_of_bitを参照せずに、bitを吐き出す。
	output reg [3:0] output_enable_byte,
	output reg [63:0] output_val,

	//debug
	output reg [63:0] tmp_buf_bit_offset,
	output reg [63:0] tmp_byte,
	output reg [7:0] tmp_bit
);

always @(posedge clock , posedge reset_n) begin
	if (!reset_n) begin
		tmp_buf_bit_offset <= 64'h0;
		output_val <= 64'h0;
		output_enable_byte <= 64'h0;
		tmp_bit <= 8'h0;
	end else begin
		if (enable) begin
			output_val <= {tmp_bit, 56'h0} | (val << (64 - (tmp_buf_bit_offset + size_of_bit ))) ;
			output_enable_byte <= (tmp_buf_bit_offset + size_of_bit) >> 3;
			tmp_bit <=  (({tmp_bit, 56'h0} | (val << (64 - (tmp_buf_bit_offset + size_of_bit ))))
								 << ((tmp_buf_bit_offset + size_of_bit) & 64'hffff_ffff_ffff_fff8))>>56 ;
			tmp_byte <= ((tmp_buf_bit_offset + size_of_bit) & 64'hffff_ffff_ffff_fff8);
			tmp_buf_bit_offset <= ((tmp_buf_bit_offset + size_of_bit) & 64'h7);
		end else if (flush_bit) begin
			if (tmp_buf_bit_offset) begin
				output_val <= {tmp_bit, 56'h0};
				output_enable_byte <= 4'h1;
				tmp_bit <= 0;
				tmp_buf_bit_offset <= 0;
			end else begin
				output_val <= 64'h0;
				output_enable_byte <= 4'h0;
				tmp_bit <= 0;
				tmp_buf_bit_offset <= 0;
			end
		end else begin
			output_val <= 64'h0;
			output_enable_byte <= 4'h0;
		end
		
	end

end



endmodule;