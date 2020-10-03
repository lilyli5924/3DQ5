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

module tb_experiment1a;

logic Clock_50;
logic [17:0] switch;

logic VGA_clock;
logic VGA_Hsync;
logic VGA_Vsync;
logic VGA_blank;
logic VGA_sync;
logic [7:0] VGA_red;
logic [7:0] VGA_green;
logic [7:0] VGA_blue;

// Instantiate the unit under test
experiment1a uut (
		.CLOCK_50_I(Clock_50),
		.SWITCH_I(switch),
		.VGA_CLOCK_O(VGA_clock),
		.VGA_HSYNC_O(VGA_Hsync),
		.VGA_VSYNC_O(VGA_Vsync),
		.VGA_BLANK_O(VGA_blank),
		.VGA_SYNC_O(VGA_sync),
		.VGA_RED_O(VGA_red),
		.VGA_GREEN_O(VGA_green),
		.VGA_BLUE_O(VGA_blue)
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
	switch[17] = 1'b1;
	// Activate reset for 2 clock cycles
	@ (posedge Clock_50);
	@ (posedge Clock_50);	
	switch[17] = 1'b0;	
end
endtask

// Initialize signals
initial begin
	Clock_50 = 1'b0;
	switch = 18'd0;
	
	// Apply master reset
	master_reset;
	
	// run simulation for 1.5 ms
	# 1500000;
	$stop;
end

endmodule
