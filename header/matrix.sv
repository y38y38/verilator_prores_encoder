module matrix (
	input wire clock,
	input wire reset_n,
	input wire [31:0] Y_QMAT[8][8],
	input wire [31:0] C_QMAT[8][8],
	output reg output_enable,
	output reg [63:0] val,
	output reg [63:0] size_of_bit,
	output reg flush_bit,
	output reg [31:0] counter

);


always @(posedge clock ,negedge reset_n) begin
	if(!reset_n) begin
		val <= 64'h0;
		counter <= 32'h0;
	end else begin
		counter <= counter + 1;
	end
end

always @(posedge clock ,negedge reset_n) begin
	if(!reset_n) begin
		output_enable <= 1'b0;
		size_of_bit <= 64'h00;
		flush_bit <= 1'b0;
		val <= 64'h0;
	end else begin
		if (counter > 15) begin
				output_enable <= 1'b0;
				size_of_bit <= 64'h00;
				flush_bit <= 1'b0;
				val <= 64'h0;
			
		end
	end
end



genvar i,j;
generate
for(i=0;i<8;i++) begin
	for(j=0;j<8;j++) begin
		always@(posedge clock, negedge reset_n) begin
			if(!reset_n) begin
			end else begin
				if (counter == (i*8)+j) begin
					output_enable <= 1'b1;
					size_of_bit <= 64'h8;
					flush_bit <= 1'b0;
					val[63:8] <= 56'h0;
					val[7:0] <= Y_QMAT[i][j][7:0];
				end
			end
		end
	end
end
endgenerate;

genvar k,l;
generate
for(k=0;k<8;k++) begin
	for(l=0;l<8;l++) begin
		always@(posedge clock, negedge reset_n) begin
			if(!reset_n) begin
			end else begin
				if (counter == 64 + (k*8) + l) begin
					output_enable <= 1'b1;
					size_of_bit <= 64'h8;
					flush_bit <= 1'b0;
					val[63:8] <= 56'h0;
					val[7:0]   <= C_QMAT[k][l][7:0];
				end
			end
		end
	end
end



endgenerate;

endmodule;