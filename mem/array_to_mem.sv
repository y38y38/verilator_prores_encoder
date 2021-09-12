module array_to_mem(
	input wire clock,
	input wire reset_n,// 0 reset , 1 not reset
	input wire [31:0] counter,
	input wire [31:0] input_data_array[8][8],
//	input wire [31:0] input_data[64],
	output reg [31:0] output_data[2048]
);

genvar i;
generate
for (i=0;i<2048;i++) begin
	always @(posedge clock, negedge reset_n) begin
		if (!reset_n) begin
			output_data[i] <= 32'h0;
		end
	end
end
endgenerate


genvar j,k;
generate
for (j=0;j<8;j++) begin
	for (k=0;k<8;k++) begin
		always @(posedge clock, negedge reset_n) begin
			if (reset_n) begin
				output_data[(counter * 64) + (j*8) + k ] 
				<= input_data_array[j][k];
			end
		end
	end
end
endgenerate

endmodule;
