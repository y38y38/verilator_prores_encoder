module sequencer (
	input clock,
	input reset_n,
	input slice_start,
	input [31:0] block_num,
 	output reg [31:0] sequence_counter,
	output reg sequence_valid,
	output reg dc_vlc_reset,
 	output wire [31:0] dc_vlc_counter,
	output reg ac_vlc_reset,
	output reg [31:0] sequence_counter2
);

always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		sequence_counter <= 32'h0;
	end else begin
		sequence_counter <= sequence_counter + 32'h1;
 	end
end

localparam DCT_TIME = 12;

always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		dc_vlc_reset <=0;
	end else begin
		if (sequence_counter == DCT_TIME + block_num) begin
			dc_vlc_reset <= 0;
		end else if (sequence_counter == DCT_TIME + block_num + 1) begin
			dc_vlc_reset <= 1;
		end
	end
end


assign	dc_vlc_counter = sequence_counter - (block_num + DCT_TIME + 1);


localparam DC_VLC_TIME = 44;
always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		ac_vlc_reset <=0;
	end else begin
		if (sequence_counter == DCT_TIME + block_num + DC_VLC_TIME) begin
			ac_vlc_reset <= 0;
		end else if (sequence_counter == DCT_TIME + block_num + DC_VLC_TIME + 1) begin
			ac_vlc_reset <= 1;
		end else if (sequence_counter == DCT_TIME + block_num + DC_VLC_TIME + (63* block_num) + 6) begin
			ac_vlc_reset <= 0;
		end 
	end
end


always @(posedge clock, negedge reset_n) begin
	if(!reset_n) begin
		sequence_counter2 <= 32'h0;
	end else begin
		sequence_counter2 <= (sequence_counter + 2 - DCT_TIME);
 	end
end


endmodule;
