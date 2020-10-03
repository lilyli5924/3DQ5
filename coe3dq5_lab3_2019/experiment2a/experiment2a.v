/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

module experiment2a (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[7:0] VGA_RED_O,              // VGA red
		output logic[7:0] VGA_GREEN_O,            // VGA green
		output logic[7:0] VGA_BLUE_O              // VGA blue
);

`include "VGA_Param.h"

logic system_resetn;
logic Clock_50, Clock_25, Clock_25_locked;

// For VGA
logic [9:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

assign system_resetn = ~(SWITCH_I[17] || ~Clock_25_locked);

// PLL for clock generation
CLOCK_25_PLL CLOCK_25_PLL_inst (
	.areset(SWITCH_I[17]),
	.inclk0(CLOCK_50_I),
	.c0(Clock_50),
	.c1(Clock_25),
	.locked(Clock_25_locked)
);

// VGA unit
logic [9:0] VGA_RED_O_long, VGA_GREEN_O_long, VGA_BLUE_O_long;
VGA_Controller VGA_unit(
	.Clock(Clock_25),
	.Resetn(system_resetn),

	.iRed(VGA_red),
	.iGreen(VGA_green),
	.iBlue(VGA_blue),
	.oCoord_X(pixel_X_pos),
	.oCoord_Y(pixel_Y_pos),
	
	//	VGA Side
	.oVGA_R(VGA_RED_O_long),
	.oVGA_G(VGA_GREEN_O_long),
	.oVGA_B(VGA_BLUE_O_long),
	.oVGA_H_SYNC(VGA_HSYNC_O),
	.oVGA_V_SYNC(VGA_VSYNC_O),
	.oVGA_SYNC(VGA_SYNC_O),
	.oVGA_BLANK(VGA_BLANK_O),
	.oVGA_CLOCK(VGA_CLOCK_O)
);

assign VGA_RED_O = VGA_RED_O_long[9:2];
assign VGA_GREEN_O = VGA_GREEN_O_long[9:2];
assign VGA_BLUE_O = VGA_BLUE_O_long[9:2];

always_comb begin
	VGA_red = 10'h000;
	VGA_green = 10'h000;
	if (pixel_X_pos == 10'd0 || pixel_X_pos == H_SYNC_ACT-1 || 
		pixel_Y_pos == 10'd0 || pixel_Y_pos == V_SYNC_ACT-1) begin
		VGA_blue = 10'h3FF;
	end else begin
		VGA_blue = 10'h000;
	end
end

endmodule
