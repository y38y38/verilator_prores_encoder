module array(
	input clock,
	input reset,
	input [31:0] counter,
	input [31:0] input_data[64],
);

genvar i,j;
for (i=0;i<8;i++) begin
	for (j=0;j<8;j++) begin
		assign output_array_data[i][j] = input_data[(i*8)+j];
	end
end


endmodule;
