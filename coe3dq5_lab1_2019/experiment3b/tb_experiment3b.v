/*
Copyright by Phillip Kinsman and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps

`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

module tb_experiment3b;

	logic CLOCK;
	logic RESETN;
	logic LOAD;
	logic [3:0] LOAD_VALUE [1:0];

	assign LOAD_VALUE = { 4'h0, 4'h0 };

	experiment3b uut (
		.CLOCK_I(CLOCK),
		.RESETN_I(RESETN),
		.LOAD_I(LOAD),
		.LOAD_VALUE_I(LOAD_VALUE),
		.BCD_COUNT_O());

	initial begin
		// Initialize all signals
		CLOCK = 1'b0;
		RESETN = 1'b0;
		LOAD = 1'b0;

		#10

		// After 10ns, turn off global reset
		RESETN = 1'b1;

		#210

		// At time 220ns, simulate a load operation
		// by asserting the LOAD signal for 1cc
		LOAD = 1'b1;
		#10
		LOAD = 1'b0;
	end

	always begin
		CLOCK = #5 ~CLOCK;
	end

endmodule
