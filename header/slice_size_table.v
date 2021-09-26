module slice_size_table(
	input wire clock,
	input wire reset_n,
	input wire [31:0] slice_num,

	output reg output_enable,
	output reg [63:0] val,
	output reg [63:0] size_of_bit,
	output reg flush_bit,
	output reg [31:0] counter

);

always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		counter <= 32'h0;
	end else begin
		counter <= counter +1;
	end
end


always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		output_enable <= 1'b0;
		val <= 64'h00;
		size_of_bit <= 64'h0;
		flush_bit <= 1'b0;
	end else begin
		if(counter <= slice_num) begin
			//dummy size table
			output_enable <= 1'b1;
			val <= 64'h00;
			size_of_bit <= 64'h10;
			flush_bit <= 1'b0;
			//$display("%d", counter);
		end else begin
			output_enable <= 1'b0;
			val <= 64'h00;
			size_of_bit <= 64'h0;
			flush_bit <= 1'b0;
		end
	end
end


endmodule;

