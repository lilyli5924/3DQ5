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

module tb_experiment2a;

logic Clock_50;
logic Resetn;

logic [8:0] Address;
logic [7:0] Read_data [1:0];
logic [7:0] Write_data [1:0];
logic Write_enable [1:0];

// Instantiate the unit under test
experiment2a uut (
		.CLOCK_I(Clock_50),
		.RESETN_I(Resetn),
		.ADDRESS_O(Address),
		.READ_DATA_O(Read_data),
		.WRITE_DATA_O(Write_data),
		.WRITE_ENABLE_O(Write_enable)
);

// Generate a 50 MHz clock
always begin
	# 10;
	Clock_50 = ~Clock_50;
end

task master_reset;
begin
	wait (Clock_50 !== 1'bx);
	@ (posedge Clock_50);
	Resetn = 1'b0;
	// Activate reset for 2 clock cycles
	@ (posedge Clock_50);
	@ (posedge Clock_50);	
	Resetn = 1'b1;	
end
endtask

// Initialize signals
initial begin
	Clock_50 = 1'b0;
	Resetn = 1'b1;
	
	// Apply master reset
	master_reset;
	
	// run simulation for 25 us
	# 25000;
	$stop;
end

endmodule
