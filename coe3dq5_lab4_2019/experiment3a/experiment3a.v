/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

module experiment3a (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_I,           // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays

		/////// PS2                               ////////////
		input logic PS2_DATA_I,                   // PS2 data
		input logic PS2_CLOCK_I,                   // PS2 clock
		
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

parameter TEXTBOX_X = 160,
  		  TEXTBOX_X_SIZE = 320,
  		  TEXTBOX_Y = 120,
  		  TEXTBOX_Y_SIZE = 240;

logic system_resetn;

// For VGA
logic [9:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;
logic ram_update_enable;
logic vertical_blanking;
logic out_of_area;
logic [10:0] VGA_data_counter;
logic boarder_on;
logic text_on;
logic [9:0] pixel_X_pos_a1;

// For code storage RAM
logic [5:0] write_data;
logic [10:0] address;
logic write_enable;
logic [5:0] converted_code;

// For Character ROM
logic [5:0] character_address;
logic rom_mux_output;

// For PS/2
enum logic [1:0] {
	S_PS2_IDLE,
	S_PS2_ROM_DELAY,
	S_PS2_WRITE_RAM,
	S_PS2_FULL
} PS2_state;

logic [7:0] PS2_code;
logic PS2_code_ready;
logic PS2_code_ready_buf;
logic PS2_make_code;
logic PS2_write_enable;
logic [10:0] PS2_data_counter;

// For Push button
logic [3:0] PB_pushed;

// For cleaning display
logic clean_mode;
logic [10:0] clean_counter;

// For 7-segment displays
logic [6:0] value_7_segment [5:0];

assign system_resetn = ~SWITCH_I[17];

// VGA unit
logic [9:0] VGA_RED_O_long, VGA_GREEN_O_long, VGA_BLUE_O_long;
VGA_Controller VGA_unit(
	.Clock(CLOCK_50_I),
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

// Push Button unit
PB_Controller PB_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(system_resetn),
	.PB_signal(PUSH_BUTTON_I),	
	.PB_pushed(PB_pushed)
);

// PS2 unit
PS2_controller ps2_unit (
	.Clock(CLOCK_50_I),
	.Resetn(system_resetn),
	.PS2_clock(PS2_CLOCK_I),
	.PS2_data(PS2_DATA_I),
	.PS2_code(PS2_code),
	.PS2_code_ready(PS2_code_ready),
	.PS2_make_code(PS2_make_code)
);

// ROM for converting PS2 code to Char ROM code
PS2_to_Char_ROM convertor_ROM (
	.address(PS2_code),
	.clock(CLOCK_50_I),
	.q(converted_code)
);

// RAM for storing Char ROM code
single_port_RAM	single_port_RAM_inst0 (
	.address ( address ),
	.clock ( CLOCK_50_I ),
	.data ( write_data ),
	.wren ( write_enable ),
	.q ( character_address )
	);

// Character ROM
char_rom char_rom_unit (
	.Clock(CLOCK_50_I),
	.Character_address(character_address),
	.Font_row(pixel_Y_pos[2:0]),
	.Font_col(pixel_X_pos[2:0]),	
	.Rom_mux_output(rom_mux_output)
);

convert_hex_to_seven_segment unit5 (
	.hex_value({1'b0, VGA_data_counter[10:8]}), 
	.converted_value(value_7_segment[5])
);

convert_hex_to_seven_segment unit4 (
	.hex_value(VGA_data_counter[7:4]), 
	.converted_value(value_7_segment[4])
);

convert_hex_to_seven_segment unit3 (
	.hex_value(VGA_data_counter[3:0]), 
	.converted_value(value_7_segment[3])
);

convert_hex_to_seven_segment unit2 (
	.hex_value({1'b0, PS2_data_counter[10:8]}), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(PS2_data_counter[7:4]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(PS2_data_counter[3:0]), 
	.converted_value(value_7_segment[0])
);

// For enabling RAM update at the right time
assign vertical_blanking = (pixel_Y_pos >= V_SYNC_ACT);
assign out_of_area = ~(pixel_X_pos >= TEXTBOX_X && pixel_X_pos < TEXTBOX_X + TEXTBOX_X_SIZE
	 && pixel_Y_pos >= TEXTBOX_Y && pixel_Y_pos < TEXTBOX_Y + TEXTBOX_Y_SIZE);

always_comb begin
	if (SWITCH_I[1] == 1'b1) begin
		if (clean_mode == 1'b1) ram_update_enable = 1'b1;
		else ram_update_enable = PS2_write_enable;
	end else begin
		if (SWITCH_I[0] == 1'b1) ram_update_enable = out_of_area;
		else ram_update_enable = vertical_blanking;
	end
end

// For controlling the signals to the storage RAM
always_comb begin
	write_data = converted_code;
	
	if (ram_update_enable == 1'b1) begin
		if (clean_mode == 1'b1) begin
			address = clean_counter;
			write_enable = 1'b1;
			write_data = 6'o40;
		end	else begin
			address = PS2_data_counter;
			write_enable = PS2_write_enable;
		end
	end else begin
		address = VGA_data_counter;
		write_enable = 1'b0;
	end
end

// For cleaning the screen when push button 0 is pressed
always_ff @ (posedge CLOCK_50_I or negedge system_resetn) begin
	if (system_resetn == 1'b0) begin
		clean_mode <= 1'b0;
		clean_counter <= 11'd0;
	end else begin
		if (PB_pushed[0] == 1'b1) begin
			clean_mode <= 1'b1;
			clean_counter <= 11'd0;			
		end else begin
			if (ram_update_enable == 1'b1 && clean_mode == 1'b1) begin
				if (clean_counter < 11'd2047)
					clean_counter <= clean_counter + 11'd1;
				else
					clean_mode <= 1'b0;
			end
		end		
	end
end

// FSM for monitoring PS2 keyboard
always_ff @ (posedge CLOCK_50_I or negedge system_resetn) begin
	if (system_resetn == 1'b0) begin
		PS2_state <= S_PS2_IDLE;
		PS2_code_ready_buf <= 1'b0;
		PS2_data_counter <= 11'd0;
		PS2_write_enable <= 1'b0;
	end else begin
		PS2_code_ready_buf <= PS2_code_ready;
			
		case (PS2_state)
		S_PS2_IDLE: begin
			// Scan code is detected
			if (PS2_code_ready && ~PS2_code_ready_buf && PS2_make_code == 1'b1) begin
				PS2_state <= S_PS2_ROM_DELAY;
			end
		end
		S_PS2_ROM_DELAY: begin
			// One clock cycle delay for the code conversion
			PS2_write_enable <= 1'b1;
			PS2_state <= S_PS2_WRITE_RAM;
		end
		S_PS2_WRITE_RAM: begin
			PS2_write_enable <= 1'b0;
			if (PS2_data_counter < 11'd1200) begin
				PS2_data_counter <= PS2_data_counter + 11'd1;
				PS2_state <= S_PS2_IDLE;
			end else begin
				// 1200 keys are pressed
				PS2_state <= S_PS2_FULL;
			end
		end
		default: PS2_state <= S_PS2_IDLE;
		endcase
		
		if (clean_mode == 1'b1) PS2_data_counter <= 11'd0;		
	end
end

// the latency through the embedded memories is 2 clock cycles (1 for RAM and 1 for ROM)
// pixel_X_pos[9:0] changes every second 50MHz clock cycle (because of the 640x480 mode)
// since the RAM and ROM are clocked at 50MHz, pixel_X_pos is advanced by only one value
assign pixel_X_pos_a1 = pixel_X_pos + 10'd1;
assign VGA_data_counter = ((pixel_Y_pos[9:3] - 15) * 40) + (pixel_X_pos_a1[9:3] - 20);

// RGB signals
always_comb begin
	VGA_red = 10'd0;
	VGA_green = 10'd0;
	VGA_blue = 10'd0;
	
	if (boarder_on) begin
		// Red border
		VGA_blue = 10'h3FF;
	end
	
	if (text_on) begin
		// Display text
		VGA_blue = 10'h3FF;
		VGA_green = 10'h3FF;
		VGA_red = 10'h3FF;		
	end
end

// Check if the boarder for the text box should be displayed or not
always_comb begin
	boarder_on = 1'b0;
	
	if ((pixel_X_pos >= TEXTBOX_X-1 && pixel_X_pos <= TEXTBOX_X + TEXTBOX_X_SIZE && pixel_Y_pos == TEXTBOX_Y-1)
	|| (pixel_X_pos >= TEXTBOX_X-1 && pixel_X_pos <= TEXTBOX_X + TEXTBOX_X_SIZE && pixel_Y_pos == TEXTBOX_Y + TEXTBOX_Y_SIZE)
	|| (pixel_Y_pos >= TEXTBOX_Y-1 && pixel_Y_pos <= TEXTBOX_Y + TEXTBOX_Y_SIZE && pixel_X_pos == TEXTBOX_X - 1)	
	|| (pixel_Y_pos >= TEXTBOX_Y-1 && pixel_Y_pos <= TEXTBOX_Y + TEXTBOX_Y_SIZE && pixel_X_pos == TEXTBOX_X + TEXTBOX_X_SIZE))
		boarder_on = 1'b1;
end

// Check if the text should be displayed or not
always_comb begin
	text_on = 1'b0;
	
	if (pixel_X_pos >= TEXTBOX_X && pixel_X_pos < TEXTBOX_X + TEXTBOX_X_SIZE
	 && pixel_Y_pos >= TEXTBOX_Y && pixel_Y_pos < TEXTBOX_Y + TEXTBOX_Y_SIZE)
		text_on = rom_mux_output;
end

assign	SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
		SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
		SEVEN_SEGMENT_N_O[2] = value_7_segment[2],
		SEVEN_SEGMENT_N_O[3] = 7'h7f,
		SEVEN_SEGMENT_N_O[4] = value_7_segment[3],
		SEVEN_SEGMENT_N_O[5] = value_7_segment[4],
		SEVEN_SEGMENT_N_O[6] = value_7_segment[5],
		SEVEN_SEGMENT_N_O[7] = 7'h7f;
		
endmodule
