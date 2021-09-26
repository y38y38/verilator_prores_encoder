module frame_header (
	input wire clock,
	input wire reset_n,
	input wire [15:0]horizontal,
	input wire [15:0]vertical,
	input wire [1:0] chroma_format,
	input wire [1:0] interlace_mode,
	input wire [3:0] aspect_ratio_information,
	input wire [3:0] frame_rate_code,
	input wire [7:0] color_primaries,
	input wire [7:0] transfer_characteristic,
	input wire [7:0] matrix_coefficients,
	input wire [3:0] alpha_channel_type,
	input wire [31:0] Y_QMAT[8][8],
	input wire [31:0] C_QMAT[8][8],
	output reg output_enable,
	output reg [63:0] val,
	output reg [63:0] size_of_bit,
	output reg flush_bit
);
reg [31:0] counter;


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
			val <= 64'h0;
			size_of_bit <= 64'h20;
			flush_bit <= 1'b0;
		end else if(counter == 32'h 2) begin
			//icpf;
			output_enable <= 1'b1;
			val <= 64'h69637066;
			size_of_bit <= 64'h20;
			flush_bit <= 1'b0;
		end else if(counter == 32'h3) begin
			//frame header size;
			output_enable <= 1'b1;
			val <= 64'h94;
			size_of_bit <= 64'h10;
			flush_bit <= 1'b0;
		end else if(counter == 32'h4) begin
			//reserve;
			output_enable <= 1'b1;
			val <= 64'h0;
			size_of_bit <= 64'h8;
			flush_bit <= 1'b0;
		end else if(counter == 32'h5) begin
			//bitstream version
			output_enable <= 1'b1;
			val <= 64'h0;
			size_of_bit <= 64'h8;
			flush_bit <= 1'b0;
		end else if(counter == 32'h6) begin
			//encoder identifier
			output_enable <= 1'b1;
			val <= 64'h4c617663;
			size_of_bit <= 64'h20;
			flush_bit <= 1'b0;
		end else if(counter == 32'h7) begin
			//encoder horizontal
			output_enable <= 1'b1;
			val <= {48'h0, horizontal};
			size_of_bit <= 64'h10;
			flush_bit <= 1'b0;
		end else if(counter == 32'h8) begin
			//encoder vertical
			output_enable <= 1'b1;
			val <= {48'h0, vertical};
			size_of_bit <= 64'h10;
			flush_bit <= 1'b0;
		end else if(counter == 32'h9) begin
			//chorma_format
			output_enable <= 1'b1;
			val <= {62'h0, chroma_format};
			size_of_bit <= 64'h2;
			flush_bit <= 1'b0;
		end else if(counter == 32'ha) begin
			//reserve
			output_enable <= 1'b1;
			val <= 64'h0;
			size_of_bit <= 64'h2;
			flush_bit <= 1'b0;
		end else if(counter == 32'hb) begin
			//reserve
			output_enable <= 1'b1;
			val <= {62'h0, interlace_mode};
			size_of_bit <= 64'h2;
			flush_bit <= 1'b0;
		end else if(counter == 32'hc) begin
			//reserve
			output_enable <= 1'b1;
			val <= 64'h0;
			size_of_bit <= 64'h2;
			flush_bit <= 1'b0;
		end else if(counter == 32'hd) begin
			//reserve
			output_enable <= 1'b1;
			val <= {60'h0, aspect_ratio_information};
			size_of_bit <= 64'h4;
			flush_bit <= 1'b0;
		end else if(counter == 32'he) begin
			output_enable <= 1'b1;
			val <= {60'h0, frame_rate_code};
			size_of_bit <= 64'h4;
			flush_bit <= 1'b0;
		end else if(counter == 32'h10) begin
			output_enable <= 1'b1;
			val <= {56'h0, color_primaries};
			size_of_bit <= 64'h8;
			flush_bit <= 1'b0;
		end else if(counter == 32'h11) begin
			output_enable <= 1'b1;
			val <= {56'h0, transfer_characteristic};
			size_of_bit <= 64'h8;
			flush_bit <= 1'b0;
		end else if(counter == 32'h12) begin
			output_enable <= 1'b1;
			val <= {56'h0, matrix_coefficients};
			size_of_bit <= 64'h8;
			flush_bit <= 1'b0;
		end else if(counter == 32'h13) begin

			output_enable <= 1'b1;
			val <= 64'h4;
			size_of_bit <= 64'h4;
			flush_bit <= 1'b0;
		end else if(counter == 32'h14) begin
			output_enable <= 1'b1;
			val <= {60'h0, alpha_channel_type};
			size_of_bit <= 64'h4;
			flush_bit <= 1'b0;
		end else if(counter == 32'h15) begin
			//reserve
			output_enable <= 1'b1;
			val <= 64'h0;
			size_of_bit <= 64'h8;
			flush_bit <= 1'b0;
		end else if(counter == 32'h16) begin
			//reserve
			output_enable <= 1'b1;
			val <= 64'h0;
			size_of_bit <= 64'h6;
			flush_bit <= 1'b0;
		end else if(counter == 32'h17) begin
			//load_luma_quantization_matrix
			output_enable <= 1'b1;
			val <= 64'h1;
			size_of_bit <= 64'h1;
			flush_bit <= 1'b0;
		end else if(counter == 32'h18) begin
			//load_chroma_quantization_matrix
			output_enable <= 1'b1;
			val <= 64'h1;
			size_of_bit <= 64'h1;
			flush_bit <= 1'b0;
		end else begin
			output_enable <= 1'b0;
			val <= 64'h0;
			size_of_bit <= 64'h0;
			flush_bit <= 1'b0;

			//$display("frame header d");
		end
	end
end

endmodule;