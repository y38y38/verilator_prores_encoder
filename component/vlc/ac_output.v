module ac_output(
	input wire clock,
	input wire reset_n,//0 reset , 1 not reset
	input wire [31:0] RUN_LENGTH,
	input wire [31:0] RUN_SUM,
	input wire [31:0] LEVEL_LENGTH,
	input wire [31:0] LEVEL_SUM,
	input wire enable,
	input wire ac_vlc_output_flush,
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
		if (ac_vlc_output_flush) begin
			output_enable <= 1'b0;
			val <= 64'h0;
			size_of_bit <= 64'h0;
			flush_bit <= 1'b1;
		end else if (enable) begin
			output_enable <= 1'b1;
			val <= ({32'h0, RUN_SUM}<<LEVEL_LENGTH)|{32'h0, LEVEL_SUM};
			size_of_bit <= {32'h0, RUN_LENGTH + LEVEL_LENGTH};
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
