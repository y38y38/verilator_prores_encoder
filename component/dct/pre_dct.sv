`timescale 1ns / 1ps


module pre_dct (
	input wire CLOCK,
	input wire RESET,
	input wire [31:0] INPUT_DATA[8][8],
	output reg [31:0] OUTPUT_DATA[8][8]
);


genvar  j,k;
for(j=0;j<8;j++) begin
	for(k=0;k<8;k++) begin
		always @(posedge CLOCK) begin
			if(RESET==1'b0) begin
				OUTPUT_DATA[j][k] <= 32'h0;
			end else begin
				OUTPUT_DATA[j][k] <= INPUT_DATA[j][k] - 32'h200;
			end
		end
	end
end


endmodule

