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

module tb_experiment3a;

	logic CLOCK;
	logic RESETN;

	experiment3a uut (
		.CLOCK_I(CLOCK),
		.RESETN_I(RESETN),
		.BCD_COUNT_O());

	initial begin
		CLOCK = 1'b0;
		RESETN = 1'b0;

		#10

		RESETN = 1'b1;
	end

	always begin
		CLOCK = #5 ~CLOCK;
	end

endmodule
