module exp_golomb_code(
	input reset_n,
	input clk,
	input [31:0] val,
	input [1:0] is_add_setbit,
	input [2:0]k,
	input is_ac_level,
	input is_ac_minus_n,
	output reg [31:0] sum_n,
	output reg [31:0] codeword_length

);

reg [31:0] sum;
reg [31:0] q;
reg  [1:0] is_add_setbit_n;
reg [2:0] k_n;



always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		k_n <= 3'h0;
		sum_n <= 32'h0;
		is_add_setbit_n <= 2'h0;
	end else begin
		k_n <= k;
		sum_n <= sum;
		is_add_setbit_n <= is_add_setbit;
	end
end


//exp_golomb_code
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
	end else begin
		if (is_ac_level) begin
			if (is_ac_minus_n) begin
				sum <= (val + (1<<k))<<1|1;//1clk
			end else begin
				sum <= (val + (1<<k))<<1|0;
			end
			
		end else begin
			sum <= (val + (1<<k));
		end
	end
end

//log2
//			q = getfloorclog2((val_n + (1<<(k)))) - k;

always @(posedge clk, negedge reset_n) begin
	if(!reset_n) begin
		q <= 32'h0;
	end else begin
		casez(val + (1<<(k)))
			32'b1zzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_001f - {29'h0, k};//1clk
			32'b01zz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_001e - {29'h0,k};
			32'b001z_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_001d - {29'h0,k};
			32'b0001_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_001c - {29'h0,k};
			32'b0000_1zzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_001b - {29'h0,k};
			32'b0000_01zz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_001a - {29'h0,k};
			32'b0000_001z_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_0019 - {29'h0,k};
			32'b0000_0001_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_0018 - {29'h0,k};
			32'b0000_0000_1zzz_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_0017 - {29'h0,k};
			32'b0000_0000_01zz_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_0016 - {29'h0,k};
			32'b0000_0000_001z_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_0015 - {29'h0,k};
			32'b0000_0000_0001_zzzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_0014 - {29'h0,k};
			32'b0000_0000_0000_1zzz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_0013 - {29'h0,k};
			32'b0000_0000_0000_01zz_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_0012 - {29'h0,k};
			32'b0000_0000_0000_001z_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_0011 - {29'h0,k};
			32'b0000_0000_0000_0001_zzzz_zzzz_zzzz_zzzz: q <= 32'h00_0010 - {29'h0,k};
			32'b0000_0000_0000_0000_1zzz_zzzz_zzzz_zzzz: q <= 32'h00_000f - {29'h0,k};
			32'b0000_0000_0000_0000_01zz_zzzz_zzzz_zzzz: q <= 32'h00_000e - {29'h0,k};
			32'b0000_0000_0000_0000_001z_zzzz_zzzz_zzzz: q <= 32'h00_000d - {29'h0,k};
			32'b0000_0000_0000_0000_0001_zzzz_zzzz_zzzz: q <= 32'h00_000c - {29'h0,k};
			32'b0000_0000_0000_0000_0000_1zzz_zzzz_zzzz: q <= 32'h00_000b - {29'h0,k};
			32'b0000_0000_0000_0000_0000_01zz_zzzz_zzzz: q <= 32'h00_000a - {29'h0,k};
			32'b0000_0000_0000_0000_0000_001z_zzzz_zzzz: q <= 32'h00_0009 - {29'h0,k};
			32'b0000_0000_0000_0000_0000_0001_zzzz_zzzz: q <= 32'h00_0008 - {29'h0,k};
			32'b0000_0000_0000_0000_0000_0000_1zzz_zzzz: q <= 32'h00_0007 - {29'h0,k};
			32'b0000_0000_0000_0000_0000_0000_01zz_zzzz: q <= 32'h00_0006 - {29'h0,k};
			32'b0000_0000_0000_0000_0000_0000_001z_zzzz: q <= 32'h00_0005 - {29'h0,k};
			32'b0000_0000_0000_0000_0000_0000_0001_zzzz: q <= 32'h00_0004 - {29'h0,k};
			32'b0000_0000_0000_0000_0000_0000_0000_1zzz: q <= 32'h00_0003 - {29'h0,k};
			32'b0000_0000_0000_0000_0000_0000_0000_01zz: q <= 32'h00_0002 - {29'h0,k};
			32'b0000_0000_0000_0000_0000_0000_0000_001z: q <= 32'h00_0001 - {29'h0,k};
			32'b0000_0000_0000_0000_0000_0000_0000_0001: q <= 32'h00_0000 - {29'h0,k};
			32'b0000_0000_0000_0000_0000_0000_0000_0000: q <= 32'h00_0000 - {29'h0,k};
		endcase
	end
end


always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
	end else begin
		if (is_ac_level) begin
			codeword_length <= (2 * q) + {29'h0, k_n} + 2 + {30'h0, is_add_setbit_n};//2clk
		end else begin
			codeword_length <= (2 * q) + {29'h0,k_n} + 1 + {30'h0,is_add_setbit_n};
		end
	end
end


endmodule;

