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
// It implements a 1-digit BCD counter
module experiment3a (
		input logic CLOCK_I,		
		input logic RESETN_I,
		output logic [3:0] BCD_COUNT_O
);

logic [3:0] BCD_count;

always_ff @ (posedge CLOCK_I or negedge RESETN_I) begin
	if (RESETN_I == 1'b0) begin
		BCD_count <= 4'h0;
	end else begin
		if (BCD_count < 4'd9) BCD_count <= BCD_count + 4'h1;
		else begin
			BCD_count <= 4'h0;
		end
	end
end

assign BCD_COUNT_O = BCD_count;
	
endmodule
