module sequencer (
	input clock,
	input reset_n,
	input slice_start,
	input [31:0] block_num,
 	output reg [31:0] sequence_counter,
	output reg sequence_valid,
	output reg vlc_reset
);

/*
always @(posedge clock, posedge reset_n) begin
	if(!reset_n) begin
		sequence_valid <= 1'b0;
	end else begin
		if (slice_start == 1'b1) begin
			sequence_valid <= 1'b1;
		end
	end
end
*/

always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		sequence_counter <= 32'h0;
	end else begin
//		if (slice_start ) begin
//			sequence_counter <= 32'h0;
//		end else if (sequence_valid)  begin
			sequence_counter <= sequence_counter + 32'h1;
//		end
 	end
end

localparam DCT_TIME = 12;

always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		vlc_reset <=0;
	end else begin
		if (sequence_counter == DCT_TIME -1 ) begin
			vlc_reset <= 1;
			
		end
	end
end

endmodule;
