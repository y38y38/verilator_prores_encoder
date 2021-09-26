
module mem_to_dc_vlc(
	input wire clock,
	input wire reset_n,// 0 reset , 1 not reset
	input wire [31:0] counter,
	input wire [31:0] block_num,
	input wire [31:0] input_data[2048],
	output reg [31:0] vlc_dc
);

always @(posedge clock, negedge reset_n) begin
	if (!reset_n) begin
		vlc_dc <= 32'h0;
	end else begin
		if ( (counter < block_num)) begin
			vlc_dc <= input_data[(counter * 64) % (block_num * MAX_PIXEL_NUM)];
		end 
	end
end

endmodule;
