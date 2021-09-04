`timescale 1ns / 1ps


module pre_quant_qt_qscale (
	input wire CLOCK,
	input wire RESET,
	input wire signed [31:0] INPUT_DATA[8][8],
	input wire signed [31:0] QSCALE,
	input wire signed [31:0] QMAT[8][8],
	output reg signed [31:0] OUTPUT_DATA[8][8]
);


genvar  j,k;
for(j=0;j<8;j++) begin
	for(k=0;k<8;k++) begin
		always @(posedge CLOCK) begin
			if(RESET==1'b0) begin
				OUTPUT_DATA[j][k] <= 32'h0;
			end else begin
				OUTPUT_DATA[j][k] <= (INPUT_DATA[j][k]<< 2) / (QSCALE * QMAT[j][k]);
//				OUTPUT_DATA[j][k] <= (INPUT_DATA[j][k]<< 2) / (QSCALE * QMAT[j][k]);
//				OUTPUT_DATA[j][k] <= (INPUT_DATA[j][k]<<2) / 12;
			end
		end
	end
end


endmodule

