module picture_header(
	input wire clock,
	input wire reset_n,

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
		val <= 64'h0;
		size_of_bit <= 64'h0;
		flush_bit <= 1'b0;
	end else begin
		if(counter == 32'h1) begin
			//frame_size;
			output_enable <= 1'b1;
			val <= 64'h8;
			size_of_bit <= 64'h5;
			flush_bit <= 1'b0;
		end else if(counter == 32'h 2) begin
			//reserve
			output_enable <= 1'b1;
			val <= 64'h0;
			size_of_bit <= 64'h3;
			flush_bit <= 1'b0;
		end else if(counter == 32'h 3) begin
			//picture size
			output_enable <= 1'b1;
			val <= 64'h42e;
			size_of_bit <= 64'h20;
			flush_bit <= 1'b0;
		end else if(counter == 32'h 4) begin
			//slice num
			output_enable <= 1'b1;
			val <= 64'h1;
			size_of_bit <= 64'h10;
			flush_bit <= 1'b0;
		end else if(counter == 32'h 5) begin
			//reserve
			output_enable <= 1'b1;
			val <= 64'h0;
			size_of_bit <= 64'h2;
			flush_bit <= 1'b0;
		end else if(counter == 32'h 6) begin
			//log2_desired_slice_size_in_mb
			output_enable <= 1'b1;
			val <= 64'h3;
			size_of_bit <= 64'h2;
			flush_bit <= 1'b0;
		end else if(counter == 32'h 7) begin
			//reserve
			output_enable <= 1'b1;
			val <= 64'h0;
			size_of_bit <= 64'h4;
			flush_bit <= 1'b0;
		end else if(counter == 32'h 8) begin
			//slice talbe ( slice size)
			output_enable <= 1'b1;
			val <= 64'h424;
			size_of_bit <= 64'h10;
			flush_bit <= 1'b0;
		end else if(counter == 32'h 9) begin
			//slice header size
			output_enable <= 1'b1;
			val <= 64'h6;
			size_of_bit <= 64'h5;
			flush_bit <= 1'b0;
		end else if(counter == 32'h a) begin
			//reserve
			output_enable <= 1'b1;
			val <= 64'h0;
			size_of_bit <= 64'h3;
			flush_bit <= 1'b0;
		end else if(counter == 32'h b) begin
			//qscale
			output_enable <= 1'b1;
			val <= 64'h3;
			size_of_bit <= 64'h8;
			flush_bit <= 1'b0;
		end else if(counter == 32'h c) begin
			//y size
			output_enable <= 1'b1;
			val <= 64'h319;
			size_of_bit <= 64'h10;
			flush_bit <= 1'b0;
		end else if(counter == 32'h d) begin
			//cb size
			output_enable <= 1'b1;
			val <= 64'h7c;
			size_of_bit <= 64'h10;
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

