module dc_output(
	input wire clock,
	input wire reset_n,//0 reset , 1 not reset
	input wire [31:0] LENGTH,
	input wire [31:0] SUM,
	input wire enable,
	output reg output_enable,
	output reg [63:0] val,
	output reg [63:0] size_of_bit,
	output reg flush_bit
);

always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
			output_enable <= 1'b0;
			val <= 64'h0;
			size_of_bit <= 64'h0;
			flush_bit <= 1'b0;
	end else begin
		if (enable) begin
			output_enable <= 1'b1;
			val <= {32'h0, SUM};
			size_of_bit <= {32'h0, LENGTH};
			flush_bit <= 1'b0;
		end else begin
			output_enable <= 1'b0;
			val <= 64'h0;
			size_of_bit <= 64'h0;
			flush_bit <= 1'b0;
		end
	end
end



endmodule;
