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

`include "define_state.h"

// This is the top testbench file

`define FEOF 32'hFFFFFFFF

`define FILE_NAME "motorcycle.ppm"
//`define FILE_NAME "chip.ppm"

module tb_experiment4a;

logic Clock_50;
logic [17:0] Switches;
logic [3:0] Push_buttons;
logic [8:0] LED_Green;
logic [6:0] seven_segment_n [7:0];

logic VGA_clock;
logic VGA_Hsync;
logic VGA_Vsync;
logic VGA_blank;
logic VGA_sync;
logic [7:0] VGA_red;
logic [7:0] VGA_green;
logic [7:0] VGA_blue;

wire [15:0] SRAM_data_io;
logic [15:0] SRAM_write_data, SRAM_read_data;
logic [19:0] SRAM_address;
logic SRAM_UB_N;
logic SRAM_LB_N;
logic SRAM_WE_N;
logic SRAM_CE_N;
logic SRAM_OE_N;

logic SRAM_resetn;

parameter VIEW_AREA_LEFT = 160,
		  VIEW_AREA_RIGHT = 480,
		  VIEW_AREA_TOP = 120,
		  VIEW_AREA_BOTTOM = 360;

// Internal variables
integer validation_file;
integer VGA_temp;
logic [7:0] VGA_file_data;
logic [7:0] expected_red, expected_green, expected_blue;
logic [9:0] VGA_row, VGA_col;
logic VGA_en;

logic UART_TX_O;

// Instantiate the unit under test
experiment4a uut (
		.CLOCK_50_I(Clock_50),
		.SWITCH_I(Switches),
		.PUSH_BUTTON_I(Push_buttons),		

		.SEVEN_SEGMENT_N_O(seven_segment_n),
		.LED_GREEN_O(LED_Green),

		.VGA_CLOCK_O(VGA_clock),
		.VGA_HSYNC_O(VGA_Hsync),
		.VGA_VSYNC_O(VGA_Vsync),
		.VGA_BLANK_O(VGA_blank),
		.VGA_SYNC_O(VGA_sync),
		.VGA_RED_O(VGA_red),
		.VGA_GREEN_O(VGA_green),
		.VGA_BLUE_O(VGA_blue),
		
		.SRAM_DATA_IO(SRAM_data_io),
		.SRAM_ADDRESS_O(SRAM_address),
		.SRAM_UB_N_O(SRAM_UB_N),
		.SRAM_LB_N_O(SRAM_LB_N),
		.SRAM_WE_N_O(SRAM_WE_N),
		.SRAM_CE_N_O(SRAM_CE_N),
		.SRAM_OE_N_O(SRAM_OE_N),
		
		.UART_RX_I(1'b1),
		.UART_TX_O(UART_TX_O)
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

// Task for filling the SRAM directly to shorten simulation time
task fill_SRAM;
integer uart_file, file_data, temp, i, new_line_count;
logic [15:0] buffer;
begin
	$write("Opening file \"%s\" for initializing SRAM\n\n", `FILE_NAME);
	uart_file = $fopen(`FILE_NAME, "rb");
	file_data = $fgetc(uart_file);
	new_line_count = 0;
	i = 0;
	while (file_data != `FEOF) begin
		if (new_line_count >= 3) begin
			// Filter out the header
			buffer[15:8] = file_data & 8'hFF;
			file_data = $fgetc(uart_file);			
			buffer[7:0] = file_data & 8'hFF;
			SRAM_component.SRAM_data[i] = buffer;
			i++;
		end
		// This is for filtering out the header of PPM file
		// Which consists of 3 lines of text
		// So check for line feed (8'h0A in ASCII) here

		if ((file_data & 8'hFF) == 8'h0A) new_line_count++;		
		file_data = $fgetc(uart_file);
	end

	$fclose(uart_file);

	$write("Finish initializing SRAM\n\n");
	uut.UART_timer = 24'h4C4B30;
end
endtask

// Task for opening the validation file for self-checking simulation
task open_validation_file; 
integer temp, new_line_count;
begin
	$write("Opening validation file \"%s\"\n\n", `FILE_NAME);
	validation_file = $fopen(`FILE_NAME, "rb");
	
	temp = $fgetc(validation_file);
	new_line_count = 0;
	
	// This is for filtering out the header of PPM file
	// Which consists of 3 lines of text
	// So check for line feed (8'h0A in ASCII) here
	while (temp != `FEOF && new_line_count < 3) begin
		// Filter out the header
		if ((temp & 8'hFF) == 8'h0A) new_line_count++;		
		if (new_line_count < 3) temp = $fgetc(validation_file);
	end
end endtask

// Initialize signals
initial begin
	// This is for setting the time format
	$timeformat(-3, 2, " ms", 10);
	
	$write("Simulation started at %t\n\n", $realtime);
	Clock_50 = 1'b0;
	Switches = 18'd0;
	SRAM_resetn = 1'b1;
	
	// Apply master reset
	master_reset;
	
	@ (posedge Clock_50);
	// Clear SRAM
	SRAM_resetn = 1'b0;
	
	@ (posedge Clock_50);
	SRAM_resetn = 1'b1;
	
	@ (posedge Clock_50);
	@ (posedge Clock_50);	

	fill_SRAM;
	$write("SRAM is now filled at %t\n\n", $realtime);

	open_validation_file;
	
	wait (uut.top_state == 0);
	$write("Start self-checking on VGA output at %t\n\n", $realtime);
			
	@ (negedge VGA_Vsync);
	$write("\nFinish simulating one frame for 640x480 @ 60 Hz at %t...\n", $realtime);
	$write("No mismatch found...\n\n");
	$fclose(validation_file);
	$stop;
end
 
// This always block checks to see if the RGB data obtained from the design matches with the PPM file
always @ (posedge Clock_50) begin
	if (~VGA_Vsync) begin
		VGA_en <= 1'b0;
		VGA_row <= 10'h000;
		VGA_col <= 10'h000;
	end else begin
		VGA_en <= ~VGA_en;
		// In 640x480 @ 60 Hz mode, data is provided at every other clock cycle when using 50 MHz clock
		if (VGA_en) begin
			if (uut.VGA_enable) begin
				// Delay pixel_X_pos and pixel_Y_pos to match the VGA controller
				VGA_row <= uut.VGA_unit.pixel_Y_pos;
				VGA_col <= uut.VGA_unit.pixel_X_pos;
				
				if (VGA_row == VIEW_AREA_TOP && VGA_col == VIEW_AREA_LEFT) $write("Entering 320x240 display area...\n\n");
				if (VGA_row == VIEW_AREA_BOTTOM && VGA_col == VIEW_AREA_RIGHT) $write("Leaving 320x240 display area...\n\n");
				
				// In display area
				if ((VGA_row >= VIEW_AREA_TOP && VGA_row < VIEW_AREA_BOTTOM)
	 			 && (VGA_col >= VIEW_AREA_LEFT && VGA_col < VIEW_AREA_RIGHT)) begin
	 			
	 				// Get expected data from PPM file
	 				VGA_file_data = $fgetc(validation_file);
					expected_red = VGA_file_data & 8'hFF;
	 				VGA_file_data = $fgetc(validation_file);
					expected_green = VGA_file_data & 8'hFF;
	 				VGA_file_data = $fgetc(validation_file);
					expected_blue = VGA_file_data & 8'hFF;
							
					if (VGA_red != expected_red) begin
						$write("Red   mismatch at pixel (%d, %d): expect=%x, got=%x\n", 
							VGA_col, 
							VGA_row, 
							expected_red, 
							VGA_red);
						$stop;
					end
					if (VGA_green != expected_green) begin
						$write("Green mismatch at pixel (%d, %d): expect=%x, got=%x\n", 
							VGA_col, 
							VGA_row, 
							expected_green, 
							VGA_green);
						$stop;
					end			
					if (VGA_blue != expected_blue) begin
						$write("Blue  mismatch at pixel (%d, %d): expect=%x, got=%x\n", 
							VGA_col, 
							VGA_row, 
							expected_blue, 
							VGA_blue);
						$stop;
					end		
				end
			end 
		end
	end
end

endmodule
