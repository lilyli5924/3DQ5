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

// This is the top module of testbench

`include "define_state.h"

module tb_experiment1;

logic Clock_50;
logic [17:0] Switches;
logic [3:0] Push_buttons;
logic [8:0] LED_Green;

wire [15:0] SRAM_data_io;
logic [15:0] SRAM_write_data, SRAM_read_data;
logic [19:0] SRAM_address;
logic SRAM_UB_N;
logic SRAM_LB_N;
logic SRAM_WE_N;
logic SRAM_CE_N;
logic SRAM_OE_N;

logic SRAM_resetn;

logic mismatch;

// Instantiate the unit under test
experiment1 uut (
	.CLOCK_50_I(Clock_50),
	.SWITCH_I(Switches),
	.PUSH_BUTTON_I(Push_buttons),
	.LED_GREEN_O(LED_Green),

	.SRAM_DATA_IO(SRAM_data_io),
	.SRAM_ADDRESS_O(SRAM_address),
	.SRAM_UB_N_O(SRAM_UB_N),
	.SRAM_LB_N_O(SRAM_LB_N),
	.SRAM_WE_N_O(SRAM_WE_N),
	.SRAM_CE_N_O(SRAM_CE_N),
	.SRAM_OE_N_O(SRAM_OE_N)
);

// The emulator for the external SRAM during simulation
tb_SRAM_Emulator SRAM_component (
	.Clock_50(Clock_50),
	.Resetn(SRAM_resetn),
	
	.SRAM_data_io(SRAM_data_io),
	.SRAM_address(SRAM_address[17:0]),
	.SRAM_UB_N(SRAM_UB_N),
	.SRAM_LB_N(SRAM_LB_N),
	.SRAM_WE_N(SRAM_WE_N),
	.SRAM_CE_N(SRAM_CE_N),
	.SRAM_OE_N(SRAM_OE_N)
);

// Generate a 50 MHz clock
always begin
	# 10;
	Clock_50 = ~Clock_50;
end

// Task for generating master reset
task master_reset;
begin
	wait (Clock_50 !== 1'bx);
	@ (posedge Clock_50);
	$write("Applying global reset...\n\n");
	Switches[17] = 1'b1;
	// Activate reset for 2 clock cycles
	@ (posedge Clock_50);
	@ (posedge Clock_50);	
	Switches[17] = 1'b0;	
	$write("Removing global reset...\n\n");	
end
endtask

// Initialize signals
initial begin
	// This is for setting the time format
	$timeformat(-6, 2, " us", 10);
	
	Clock_50 = 1'b0;
	Switches = 18'd0;
	SRAM_resetn = 1'b1;
	Push_buttons = 4'hF;
	
//	Switches[0] = 1'b1;	// Stuck at address
//	Switches[1] = 1'b1;	// Stuck at write data
//	Switches[2] = 1'b1;	// Stuck at write enable
//	Switches[3] = 1'b1;	// Stuck at read data
	
	// Apply master reset
	master_reset;
	
	@ (posedge Clock_50);
	// Clear SRAM
	SRAM_resetn = 1'b0;
	
	@ (posedge Clock_50);
	SRAM_resetn = 1'b1;
	
	@ (posedge Clock_50);
	@ (posedge Clock_50);	
	
	// Activate Push button 0
	$write("Start signal issued for PB0...\n\n");
	Push_buttons[0] = 1'b0;
		
	@ (posedge uut.PB_pushed[0]);
	$write("Pulse generated for PB0...\n\n");
	Push_buttons[0] = 1'b1;
	
	# 200;
	
	// run simulation until BIST is done
	@ (posedge uut.BIST_finish);
	
	$write("\nBIST finish at %t...\n", $realtime);
	$write("No mismatch found...\n\n");
	#20;
	$stop;
end

// Self-checking testbench
always @ (posedge uut.BIST_unit.BIST_mismatch) begin

	// Display error message	
	$write("///////////////////////////\n");
	$write("Mismatch found at %t\n", $realtime);
	$write("///////////////////////////\n");
	
	$stop;
end

// This shows the progress of the SRAM BIST engine
always @ (posedge Clock_50) begin	
	// Only display data in the Read cycle
	if (uut.BIST_unit.BIST_address[13:0] == 14'h3FFF) begin		
	
		// Note: the data from the current address will be available two clock cycles later
		$write("State = %s, Current address = %d (%h), Read data = %h, Write data = %h\n",
			uut.BIST_unit.BIST_state,
			uut.BIST_unit.BIST_address,
			uut.BIST_unit.BIST_address,
			uut.BIST_unit.BIST_read_data,
			uut.BIST_unit.BIST_write_data
		);
	end	
end

/*
logic [15:0] expected_data;

// This is for probing the internal signals during simulation for debugging
always @ (posedge Clock_50) begin	
	// Only display data in the Read cycle
	if (uut.BIST_unit.BIST_state == S_READ_CYCLE) begin		
		
		// Expected data is computed based on the state transitions in the BIST engine
		expected_data = uut.BIST_unit.BIST_write_data - 16'd1;
		
		// Note: the data from the current address will be available two clock cycles later
		$write("State = %s, Current address = %d (%h), Read data = %h, Expected data = %h\n",
			uut.BIST_unit.BIST_state,
			uut.BIST_unit.BIST_address,
			uut.BIST_unit.BIST_address,
			uut.BIST_unit.BIST_read_data,
			expected_data
		);
	end	
end
*/

endmodule
