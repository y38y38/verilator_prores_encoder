
module mem_to_ac_vlc(
	input wire clock,
	input wire reset_n,// 0 reset , 1 not reset
	input wire [31:0] counter,
	input wire [31:0] block_num,
	input wire [31:0] input_data[2048],
	output reg [31:0] vlc_ac
	
);

wire [31:0] conefficient1;
wire [31:0] block;
wire [31:0] position;

//wire [31:0] position;

assign conefficient1 = (counter / block_num) + 1;
assign block = counter % block_num;

/*
case (conefficient1)
	32'h0: assign position = 0;
	default: assign position = 1;
endcase
*/
assign position = get_position(conefficient1);

always @(posedge clock, negedge reset_n) begin
	if (!reset_n) begin
		vlc_ac <= 32'h0;
	end else begin
		if (conefficient1 < MAX_PIXEL_NUM) begin
			vlc_ac <= input_data[(block*MAX_PIXEL_NUM)+position];
		end 
	end
end

endmodule;
function  [31:0] get_position(input [31:0] coneff);
	begin
		case (coneff)
			32'd0: get_position = 0;
			32'd1: get_position = 1;
			32'd2: get_position = 8;
			32'd3: get_position = 9;
			32'd4: get_position = 2;
			32'd5: get_position = 3;
			32'd6: get_position = 10;
			32'd7: get_position = 11;

			32'd8: get_position = 16;
			32'd9: get_position = 17;
			32'd10: get_position = 24;
			32'd11: get_position = 25;
			32'd12: get_position = 18;
			32'd13: get_position = 19;
			32'd14: get_position = 26;
			32'd15: get_position = 27;

			32'd16: get_position = 4;
			32'd17: get_position = 5;
			32'd18: get_position = 12;
			32'd19: get_position = 20;
			32'd20: get_position = 13;
			32'd21: get_position = 6;
			32'd22: get_position = 7;
			32'd23: get_position = 14;

			32'd24: get_position = 21;
			32'd25: get_position = 28;
			32'd26: get_position = 29;
			32'd27: get_position = 22;
			32'd28: get_position = 15;
			32'd29: get_position = 23;
			32'd30: get_position = 30;
			32'd31: get_position = 31;

			32'd32: get_position = 32;
			32'd33: get_position = 33;
			32'd34: get_position = 40;
			32'd35: get_position = 48;
			32'd36: get_position = 41;
			32'd37: get_position = 34;
			32'd38: get_position = 35;
			32'd39: get_position = 42;

			32'd40: get_position = 49;
			32'd41: get_position = 56;
			32'd42: get_position = 57;
			32'd43: get_position = 50;
			32'd44: get_position = 43;
			32'd45: get_position = 36;
			32'd46: get_position = 37;
			32'd47: get_position = 44;

			32'd48: get_position = 51;
			32'd49: get_position = 58;
			32'd50: get_position = 59;
			32'd51: get_position = 52;
			32'd52: get_position = 45;
			32'd53: get_position = 38;
			32'd54: get_position = 39;
			32'd55: get_position = 46;

			32'd56: get_position = 53;
			32'd57: get_position = 60;
			32'd58: get_position = 61;
			32'd59: get_position = 54;
			32'd60: get_position = 47;
			32'd61: get_position = 55;
			32'd62: get_position = 62;
			32'd63: get_position = 63;
			default: get_position = 1;
		endcase
		
	end
endfunction
