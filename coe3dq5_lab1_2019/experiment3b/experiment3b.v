/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps

`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

// This is the top module
// It implements a 2-digit BCD counter with parallel load
module experiment3b (
		input logic CLOCK_I,
		input logic RESETN_I,
		input logic LOAD_I,
		input logic [3:0] LOAD_VALUE_I [1:0],
		
		output logic [3:0] BCD_COUNT_O [1:0]
);

logic [3:0] BCD_count [1:0];

always_ff @ (posedge CLOCK_I or negedge RESETN_I) begin
	if (RESETN_I == 1'b0) begin
		BCD_count[0] <= 4'h0;
		BCD_count[1] <= 4'h0;		
	end else begin
		if (LOAD_I == 1'b1) begin
			// Parallel load
			BCD_count[0] <= LOAD_VALUE_I[0];
			BCD_count[1] <= LOAD_VALUE_I[1];			
		end else begin
			if (BCD_count[0] < 4'd9) BCD_count[0] <= BCD_count[0] + 4'h1;
			else begin
				BCD_count[0] <= 4'h0;
				if (BCD_count[1] < 4'd9) BCD_count[1] <= BCD_count[1] + 4'h1;
				else BCD_count[1] <= 4'h0;
			end
		end
	end
end

assign BCD_COUNT_O = BCD_count;
	
endmodule
