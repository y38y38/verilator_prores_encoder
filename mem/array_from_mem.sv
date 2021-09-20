
module array_from_mem(
	input wire clock,
	input wire reset_n,// 0 reset , 1 not reset
	input wire [31:0] counter,
	input wire [31:0] input_data[4096],
//	input wire [31:0] input_data[64],
	input wire [31:0] offset,
	output reg [31:0] output_data_array[8][8]
);

genvar i,l;
generate
for (i=0;i<8;i++) begin
	for (l=0;l<8;l++) begin
		always @(posedge clock, negedge reset_n) begin
			if (!reset_n) begin
				output_data_array[i][l] <= 32'h1;
			end
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
				output_data_array[j][k] 
//				<= 666;
//				<= input_data[0];
				<= input_data[offset + ((counter % MAX_BLOCK_NUM) * MAX_PIXEL_NUM)
				  + (j*8)+k];
//<= counter;
			end
		end
	end
end
endgenerate

endmodule;
