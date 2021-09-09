module array(
	input [31:0] input_data[64],
	output [31:0] output_array_data[8][8]
);

genvar i,j;
for (i=0;i<8;i++) begin
	for (j=0;j<8;j++) begin
		assign output_array_data[i][j] = input_data[(i*8)+j];
	end
end


endmodule;
