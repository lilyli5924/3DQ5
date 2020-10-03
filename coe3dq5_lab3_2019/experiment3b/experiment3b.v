/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

module experiment3b (
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
parameter OBJECT_SIZE = 10'd20,
          RED_SIZE = 150, BLUE_SIZE = 300, GREEN_SIZE = 450;

logic system_resetn;
logic Clock_50, Clock_25, Clock_25_locked;

logic object_on, object_X_direction;
logic[9:0] object_speed;

// combinational buffer line used to introduce additional delay
logic[RED_SIZE:0] red_buffer_line;
logic[BLUE_SIZE:0] blue_buffer_line;
logic[GREEN_SIZE:0] green_buffer_line;

// For VGA
logic [9:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;
logic VGA_vsync_buf;

typedef struct {
	logic [9:0] X_pos;
	logic [9:0] Y_pos;	
} coordinate_struct;

coordinate_struct object_coordinate;

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

// Check if ball should be displayed or not
always_comb begin
	if (pixel_X_pos >= object_coordinate.X_pos 
	 && pixel_X_pos < object_coordinate.X_pos + OBJECT_SIZE
	 && pixel_Y_pos >= object_coordinate.Y_pos 
	 && pixel_Y_pos < object_coordinate.Y_pos + OBJECT_SIZE) 
		object_on = 1'b1;
	else 
		object_on = 1'b0;
end


// Set up a buffer of each RGB channel that are on based on object_on
// Instead of experiment3a, this generate loop statement is used to purposely delay RGB channel by a period that is 
// VBI/HBI period.
assign red_buffer_line[0] = object_on;

// Repeater
generate
	genvar i;
	for (i=0; i<RED_SIZE; i=i+1)
	begin: instance_of_red_lcell
		lcell red_buffer (.in(red_buffer_line[i]), .out(red_buffer_line[i+1])); 
	end
endgenerate

assign blue_buffer_line[0] = object_on;
generate
	genvar j;
	for (j=0; j<BLUE_SIZE; j=j+1)
	begin: instance_of_blue_lcell
		lcell blue_buffer (.in(blue_buffer_line[j]), .out(blue_buffer_line[j+1])); 
	end
endgenerate

assign green_buffer_line[0] = object_on;
generate
	genvar k;
	for (k=0; k<GREEN_SIZE; k=k+1)
	begin: instance_of_green_lcell
		lcell green_buffer (.in(green_buffer_line[k]), .out(green_buffer_line[k+1])); 
	end
endgenerate

always_comb begin
	VGA_red = 10'h000;
	VGA_blue = 10'h000;
	VGA_green = 10'h000;
	if (red_buffer_line[RED_SIZE] == 1'b1)
		VGA_red = 10'h3FF;
	if (blue_buffer_line[BLUE_SIZE] == 1'b1)
		VGA_blue = 10'h3FF;
	if (green_buffer_line[GREEN_SIZE] == 1'b1)
		VGA_green = 10'h3FF;
end

always_ff @ (posedge Clock_25 or negedge system_resetn) begin
	if (system_resetn == 1'b0) begin
		VGA_vsync_buf <= 1'b0;
	end else begin
		VGA_vsync_buf <= VGA_VSYNC_O;
	end
end

// Updating location of the object during vertical blanking
always_ff @ (posedge Clock_25 or negedge system_resetn) begin
	if (system_resetn == 1'b0) begin
		object_coordinate.X_pos <= 10'd300;
		object_coordinate.Y_pos <= 10'd200;
		object_X_direction <= 1'b0;
	end else begin
		if (VGA_vsync_buf && ~VGA_VSYNC_O) begin
			if (object_X_direction == 1'b1) begin
				// Moving right
				if (object_coordinate.X_pos < H_SYNC_ACT - OBJECT_SIZE - object_speed) 
					object_coordinate.X_pos <= object_coordinate.X_pos + object_speed;
				else
					object_X_direction <= 1'b0;
			end else begin
				// Moving left
				if (object_coordinate.X_pos >= object_speed) 		
					object_coordinate.X_pos <= object_coordinate.X_pos - object_speed;		
				else
					object_X_direction <= 1'b1;
			end
		end
	end
end

assign object_speed = {7'd0, SWITCH_I[2:0]};

endmodule
