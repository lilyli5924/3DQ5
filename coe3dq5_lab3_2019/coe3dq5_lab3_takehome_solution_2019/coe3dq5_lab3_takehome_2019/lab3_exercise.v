/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

module lab3_exercise (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_I,           // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs
		output logic[17:0] LED_RED_O,             // 18 red LEDs

		/////// PS2                               ////////////
		input logic PS2_DATA_I,                   // PS2 data
		input logic PS2_CLOCK_I,                  // PS2 clock

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

// For Push button
logic [3:0] PB_pushed;

// For VGA
logic [9:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;
logic VGA_vsync_buf;

// For Character ROM
logic [5:0] character_address;
logic rom_mux_output;

logic [5:0] lives_character_address;

logic [5:0] score_msd_character_address;
logic [5:0] score_lsd_character_address;

logic [5:0] game_msd_character_address;
logic [5:0] game_lsd_character_address;

logic [5:0] rank_score_msd_character_address;
logic [5:0] rank_score_lsd_character_address;

logic [5:0] rank_game_msd_character_address ;
logic [5:0] rank_game_lsd_character_address;

logic [5:0] time_left_msd_character_address ;
logic [5:0] time_left_lsd_character_address;

// For the Pong game
parameter OBJECT_SIZE = 10,
		  BAR_X_SIZE = 60,
		  BAR_Y_SIZE = 5,
		  BAR_SPEED = 5,
		  SCREEN_BOTTOM = 50,
		  GAME_MESSAGE = 100,
		  TAB_MESSAGE = 200,
		  RANK_MESSAGE = 200,
		  TIME_MESSAGE = 300;

typedef struct {
	logic [9:0] X_pos;
	logic [9:0] Y_pos;	
} coordinate_struct;

coordinate_struct object_coordinate, bar_coordinate;
logic object_X_direction, object_Y_direction;
logic object_on, bar_on, screen_bottom_on;

logic welcome_screen;
logic [5:0] welcome_frame_count;
logic bar_orientation;
logic key_pressed;

logic [1:0] lives;
logic [7:0] score;
logic [7:0] game_counter;
logic [7:0] rank_game;
logic [7:0] rank_score;
logic [7:0] time_left;
logic [25:0] down_count;
logic timed_out;

logic game_over;
logic [1:0] game_over_buf;

logic [9:0] object_speed;

// For 7 segment displays
logic [6:0] value_7_segment [2:0];

logic [9:0] new_pixel_X_pos;
assign new_pixel_X_pos = pixel_X_pos + 10'd1;

assign system_resetn = ~(SWITCH_I[17] || ~Clock_25_locked);

logic [7:0] PS2_code, PS2_code_buf;
logic PS2_code_ready, PS2_code_ready_buf;
logic PS2_make_code;

// move left and right flags
logic move_left, move_right;

// PS2 unit
PS2_Controller PS2_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(system_resetn),
	
	.PS2_clock(PS2_CLOCK_I),
	.PS2_data(PS2_DATA_I),
	
	.PS2_code(PS2_code),
	.PS2_code_ready(PS2_code_ready),
	.PS2_make_code(PS2_make_code)
);

// PLL for clock generation
CLOCK_25_PLL CLOCK_25_PLL_inst (
	.areset(SWITCH_I[17]),
	.inclk0(CLOCK_50_I),
	.c0(Clock_50),
	.c1(Clock_25),
	.locked(Clock_25_locked)
);

// Push Button unit
PB_Controller PB_unit (
	.Clock_25(Clock_25),
	.Resetn(system_resetn),
	.PB_signal(PUSH_BUTTON_I),	
	.PB_pushed(PB_pushed)
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

// Character ROM
char_rom char_rom_unit (
	.Clock(VGA_CLOCK_O),
	.Character_address(character_address),
	.Font_row(pixel_Y_pos[2:0]),
	.Font_col(pixel_X_pos[2:0]),	
	.Rom_mux_output(rom_mux_output)
);

// Convert hex to character address
convert_hex_to_char_rom_address convert_lives_to_char_rom_address (
	.hex_value(lives),
	.char_rom_address(lives_character_address)
);

convert_hex_to_char_rom_address convert_score_msd_to_char_rom_address (
	.hex_value(score[7:4]),
	.char_rom_address(score_msd_character_address)
);

convert_hex_to_char_rom_address convert_score_lsd_to_char_rom_address (
	.hex_value(score[3:0]),
	.char_rom_address(score_lsd_character_address)
);

convert_hex_to_char_rom_address convert_rank_score_lsd_to_char_rom_address (
	.hex_value(rank_score[3:0]),
	.char_rom_address(rank_score_lsd_character_address));

convert_hex_to_char_rom_address convert_rank_score_msd_to_char_rom_address (
	.hex_value(rank_score[7:4]),
	.char_rom_address(rank_score_msd_character_address));

convert_hex_to_char_rom_address convert_rank_game_lsd_to_char_rom_address (
	.hex_value(rank_game[3:0]),
	.char_rom_address(rank_game_lsd_character_address));

convert_hex_to_char_rom_address convert_rank_game_msd_to_char_rom_address (
	.hex_value(rank_game[7:4]),
	.char_rom_address(rank_game_msd_character_address));

convert_hex_to_char_rom_address convert_time_left_lsd_to_char_rom_address (
	.hex_value(time_left[3:0]),
	.char_rom_address(time_left_lsd_character_address));

convert_hex_to_char_rom_address convert_time_left_msd_to_char_rom_address (
	.hex_value(time_left[7:4]),
	.char_rom_address(time_left_msd_character_address));

assign object_speed = {7'd0, SWITCH_I[2:0]};

// RGB signals
always_comb begin
	if (welcome_screen) begin
		VGA_red = 10'h3FF;
		VGA_green = 10'h3FF;
		VGA_blue = 10'h3FF;
		if (bar_orientation) begin
			if (pixel_X_pos >= 320) 
				VGA_red = 10'd0;
			if ((pixel_X_pos >= 480) || ((pixel_X_pos >= 160) && (pixel_X_pos < 320)))
				VGA_green = 10'd0;
			if ((pixel_X_pos >= 560) || ((pixel_X_pos >= 400) && (pixel_X_pos < 480)) ||
				((pixel_X_pos >= 240) && (pixel_X_pos < 320)) || 
				((pixel_X_pos >= 80) && (pixel_X_pos < 160)))
				VGA_blue = 10'd0;
		end else begin
			if (pixel_Y_pos >= 240) 
				VGA_red = 10'd0;
			if ((pixel_Y_pos >= 360) || ((pixel_Y_pos >= 120) && (pixel_Y_pos < 240)))
				VGA_green = 10'd0;
			if ((pixel_Y_pos >= 420) || ((pixel_Y_pos >= 300) && (pixel_Y_pos < 360)) ||
				((pixel_Y_pos >= 180) && (pixel_Y_pos < 240)) || 
				((pixel_Y_pos >= 60) && (pixel_Y_pos < 120)))
				VGA_blue = 10'd0;
		end
	end else begin
		VGA_red = 10'd0;
		VGA_green = 10'd0;
		VGA_blue = 10'd0;
		if (game_over == 1'b0) begin
			if (object_on) begin
				// Yellow object
				VGA_red = 10'h3FF;
				VGA_green = 10'h3FF;
			end
			
			if (bar_on) begin
				// Blue bar
				VGA_blue = 10'h3FF;
			end
			
			if (screen_bottom_on) begin
				// Red border
				VGA_red = 10'h3FF;
			end
			
			if (rom_mux_output) begin
				// Display text
				VGA_blue = 10'h3FF;
				VGA_green = 10'h3FF;
			end
		end else begin
			if (rom_mux_output) begin
				// Display text
				VGA_red = 10'h3FF;
				VGA_blue = 10'h3FF;
				VGA_green = 10'h3FF;
			end
		end
	end
end

always_ff @ (posedge Clock_25 or negedge system_resetn) begin
	if (system_resetn == 1'b0) begin
		VGA_vsync_buf <= 1'b0;
	end else begin
		VGA_vsync_buf <= VGA_VSYNC_O;
	end
end

always_ff @ (posedge Clock_25 or negedge system_resetn) begin
	if (system_resetn == 1'b0) begin
		welcome_screen <= 1'b1;
		welcome_frame_count <= 25'd0;
		bar_orientation <= 1'b0;
		key_pressed <= 1'b0;
	end else begin
		if (VGA_vsync_buf && ~VGA_VSYNC_O) begin
			welcome_frame_count <= welcome_frame_count + 6'd1;
			if (welcome_frame_count == 6'd59) begin
				welcome_frame_count <= 6'd0;
				bar_orientation <= ~bar_orientation;
			end
			if (key_pressed) begin
				key_pressed <= 1'b0;
				welcome_screen <= 1'b0;
			end				
		end
		if (PS2_code_ready && ~PS2_code_ready_buf)
			key_pressed <= 1'b1;
	end
end

always_ff @ (posedge Clock_25 or negedge system_resetn) begin
	if (system_resetn == 1'b0) begin
		down_count <= 26'd0;
		time_left <= 8'h00;
		timed_out <= 1'b0;
	end else begin
		timed_out <= 1'b0;
		down_count <= down_count - 26'd1;
		
		if (down_count == 26'd0) begin
			time_left[3:0] <= time_left[3:0] - 4'd1;
			if (time_left[3:0] == 4'd0) begin
				time_left[3:0] <= 4'd9;
				time_left[7:4] <= time_left[7:4] - 4'd1;
			end
			down_count <= 26'd24999999;
		end
		
		if ((time_left[7:4] == 4'd0) && (time_left[3:0] == 4'd1) && (down_count == 26'd0))
				if (game_over && game_over_buf[0] && game_over_buf[1])
						timed_out <= 1'b1;
						
		if (!game_over) begin
			down_count <= 26'd0;
			time_left <= 8'h00;
			timed_out <= 1'b0;
		end
		
		if (game_over_buf[0] && !game_over_buf[1]) begin
			down_count <= 26'd24999999;
			time_left <= 8'h15;
		end

	end
end

// Updating location of the object (Ball)
always_ff @ (posedge Clock_25 or negedge system_resetn) begin
	if (system_resetn == 1'b0) begin
		integer i;
		object_coordinate.X_pos <= 10'd200;
		object_coordinate.Y_pos <= 10'd50;
		object_X_direction <= 1'b1;	
		object_Y_direction <= 1'b1;	
		score <= 8'd0;		
		lives <= 2'd3;
		game_over <= 1'b0;		
		rank_score <= 8'd0;
		rank_game <= 8'd0;
	end else if (!welcome_screen) begin
		// Update movement during vertical blanking
		if (VGA_vsync_buf && ~VGA_VSYNC_O && game_over == 1'b0) begin
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
			
			if (object_Y_direction == 1'b1) begin
				// Moving down
				if (object_coordinate.Y_pos <= bar_coordinate.Y_pos - OBJECT_SIZE - object_speed)
					object_coordinate.Y_pos <= object_coordinate.Y_pos + object_speed;
				else begin
					if (object_coordinate.X_pos >= bar_coordinate.X_pos 							// Left edge of object is within bar
					 && object_coordinate.X_pos + OBJECT_SIZE <= bar_coordinate.X_pos + BAR_X_SIZE 	// Right edge of object is within bar
					) begin
							// Hit the bar
							object_Y_direction <= 1'b0;

							score[3:0] <= score[3:0] + 4'd1;
							if (score[3:0] == 4'd9) begin
								score[3:0] <= 4'd0;
								score[7:4] <= score[7:4] + 4'd1;
								if (score[7:4] == 4'd9)
									score[7:4] <= 4'd0;
							end
					end else begin
						// Hit the bottom of screen
						if (lives > 2'd0) begin
							lives <= lives - 2'd1;
						end

						if (lives > 2'd1) begin
							// Restart the object
							object_X_direction <= SWITCH_I[16];	
							object_Y_direction <= SWITCH_I[15];
							
							object_coordinate.X_pos <= 10'd200;
							object_coordinate.Y_pos <= 10'd50;
						end else begin
							// Game over
							game_over <= 1'b1;
						end				
					end
				end
			end else begin
				// Moving up
				if (object_coordinate.Y_pos >= object_speed) 				
					object_coordinate.Y_pos <= object_coordinate.Y_pos - object_speed;		
				else
					object_Y_direction <= 1'b1;
			end		
		end
		if (game_over == 1'b1) begin
		
			if (game_over_buf[0] && !game_over_buf[1]) begin
				if (score >= rank_score) begin
					rank_score <= score;
					rank_game <= game_counter;
				end
			end
			
			if (timed_out) begin
				object_coordinate.X_pos <= 10'd200;
				object_coordinate.Y_pos <= 10'd50;
				object_X_direction <= 1'b1;	
				object_Y_direction <= 1'b1;	
				score <= 8'd0;		
				lives <= 2'd3;
				game_over <= 1'b0;
			end			
			
		end
	end
end

// Update the location of bar
always_ff @ (posedge Clock_25 or negedge system_resetn) begin
	if (system_resetn == 1'b0) begin
		bar_coordinate.X_pos <= 10'd200;
		bar_coordinate.Y_pos <= 10'd0;
		move_left <= 1'b0;
		move_right <= 1'b0;
		PS2_code_ready_buf <= 1'b0;
		PS2_code_buf <= 8'd0;
	end else begin

		bar_coordinate.Y_pos <= V_SYNC_ACT-BAR_Y_SIZE-SCREEN_BOTTOM;		

		PS2_code_ready_buf <= PS2_make_code;
		
		// PS2 code is detected
		if (PS2_code_ready && ~PS2_code_ready_buf) begin
			PS2_code_buf <= PS2_code;
			if (PS2_make_code == 1'b1) begin
				if (PS2_code == 8'h1C)			// PS2 code for key 'A'
					move_left <= 1'b1;
				else if (PS2_code == 8'h1B)	// PS2 code for key 'S'
					move_right <= 1'b1;
			end else begin
				if ((PS2_code == 8'h1C) && (PS2_code_buf == 8'hF0))
					move_left <= 1'b0;
				else if ((PS2_code == 8'h1B) && (PS2_code_buf == 8'hF0))
					move_right <= 1'b0;
			end
		end
		
		// Update the movement during vertical blanking
		if (VGA_vsync_buf && ~VGA_VSYNC_O) begin
			if (move_right) begin
				// Move bar right
				if (bar_coordinate.X_pos < H_SYNC_ACT - BAR_X_SIZE - BAR_SPEED) 		
					bar_coordinate.X_pos <= bar_coordinate.X_pos + BAR_SPEED;
			end else begin
				if (move_left) begin
					// Move bar left
					if (bar_coordinate.X_pos > BAR_SPEED) 		
						bar_coordinate.X_pos <= bar_coordinate.X_pos - BAR_SPEED;
				end 	
			end
		end
	end
end

// Check if the ball should be displayed or not
always_comb begin	
	if (pixel_X_pos >= object_coordinate.X_pos && pixel_X_pos < object_coordinate.X_pos + OBJECT_SIZE
	 && pixel_Y_pos >= object_coordinate.Y_pos && pixel_Y_pos < object_coordinate.Y_pos + OBJECT_SIZE
	 && game_over == 1'b0) 
		object_on = 1'b1;
	else 
		object_on = 1'b0;
end

// Check if the bar should be displayed or not
always_comb begin
	if (pixel_X_pos >= bar_coordinate.X_pos && pixel_X_pos < bar_coordinate.X_pos + BAR_X_SIZE
	 && pixel_Y_pos >= bar_coordinate.Y_pos && pixel_Y_pos < bar_coordinate.Y_pos + BAR_Y_SIZE) 
		bar_on = 1'b1;
	else 
		bar_on = 1'b0;
end

// Check if the line on the bottom of the screen should be displayed or not
always_comb begin
	if (pixel_Y_pos == V_SYNC_ACT - SCREEN_BOTTOM + 1) 
		screen_bottom_on = 1'b1;
	else 
		screen_bottom_on = 1'b0;
end

always_ff @ (posedge Clock_25 or negedge system_resetn) begin
	if (system_resetn == 1'b0) begin
		game_counter <= 8'd0;
		game_over_buf <= 2'd0;
	end else begin	
		game_over_buf[1:0] <= {game_over_buf[0], game_over};
		if (game_over && !game_over_buf[0]) begin
			game_counter[3:0] <= game_counter[3:0] + 4'd1;
			if (game_counter[3:0] == 4'd9) begin
				game_counter[3:0] <= 4'd0;
				game_counter[7:4] <= game_counter[7:4] + 4'd1;
				if (game_counter[7:4] == 4'd9)
					game_counter [7:4] <= 4'd0;
			end
		end
	end
end

// Display text
always_comb begin
	character_address = 6'o40; // Show space by default

	if (game_over == 1'b0) begin
		if (pixel_Y_pos[9:3] == ((V_SYNC_ACT - SCREEN_BOTTOM + 20) >> 3)) begin
			// Reach the section where the text is displayed
			case (new_pixel_X_pos[9:3])
				7'd1: character_address = 6'o14; // L
				7'd2: character_address = 6'o11; // I
				7'd3: character_address = 6'o26; // V
				7'd4: character_address = 6'o05; // E
				7'd5: character_address = 6'o23; // S
				7'd6: character_address = 6'o40; // space
				7'd7: character_address = lives_character_address;
				
				7'd71: character_address = 6'o23; // S
				7'd72: character_address = 6'o03; // C
				7'd73: character_address = 6'o17; // O
				7'd74: character_address = 6'o22; // R
				7'd75: character_address = 6'o05; // E
				7'd76: character_address = 6'o40; // space
				7'd77: if (score[7:4] != 4'd0)
							character_address = score_msd_character_address; 												
				7'd78: character_address = score_lsd_character_address; 
			endcase
		end
	end else begin		
		if (pixel_Y_pos[9:3] == (GAME_MESSAGE >> 3)) begin
				case (new_pixel_X_pos[9:3])
					(TAB_MESSAGE >> 3) + 7'd0: character_address = 6'o14; // L
					(TAB_MESSAGE >> 3) + 7'd1: character_address = 6'o01; // A
					(TAB_MESSAGE >> 3) + 7'd2: character_address = 6'o23; // S
					(TAB_MESSAGE >> 3) + 7'd3: character_address = 6'o24; // T

					(TAB_MESSAGE >> 3) + 7'd5: character_address = 6'o07; // G
					(TAB_MESSAGE >> 3) + 7'd6: character_address = 6'o01; // A
					(TAB_MESSAGE >> 3) + 7'd7: character_address = 6'o15; // M
					(TAB_MESSAGE >> 3) + 7'd8: character_address = 6'o05; // E
					(TAB_MESSAGE >> 3) + 7'd9: character_address = 6'o47; // '
					(TAB_MESSAGE >> 3) + 7'd10: character_address = 6'o23; // S
									
					(TAB_MESSAGE >> 3) + 7'd12: character_address = 6'o23; // S
					(TAB_MESSAGE >> 3) + 7'd13: character_address = 6'o03; // C
					(TAB_MESSAGE >> 3) + 7'd14: character_address = 6'o17; // O
					(TAB_MESSAGE >> 3) + 7'd15: character_address = 6'o22; // R
					(TAB_MESSAGE >> 3) + 7'd16: character_address = 6'o05; // E
									
					(TAB_MESSAGE >> 3) + 7'd18: character_address = 6'o27; // W
					(TAB_MESSAGE >> 3) + 7'd19: character_address = 6'o01; // A
					(TAB_MESSAGE >> 3) + 7'd20: character_address = 6'o23; // S

					(TAB_MESSAGE >> 3) + 7'd22: if (score[7:4] != 4'd0)
															character_address = score_msd_character_address;
					(TAB_MESSAGE >> 3) + 7'd23: character_address = score_lsd_character_address;
			endcase
		end
		
		if ((pixel_Y_pos[9:3] == (RANK_MESSAGE >> 3)) && 
			!((game_counter [7:4] == 4'd0) && (game_counter [3:0] == 4'd0))) begin
			case (new_pixel_X_pos[9:3])
				(TAB_MESSAGE >> 3) + 7'd0: character_address = 6'o07; // G
				(TAB_MESSAGE >> 3) + 7'd1: character_address = 6'o01; // A
				(TAB_MESSAGE >> 3) + 7'd2: character_address = 6'o15; // M
				(TAB_MESSAGE >> 3) + 7'd3: character_address = 6'o05; // E
								
				(TAB_MESSAGE >> 3) + 7'd5: if (rank_game[7:4] != 4'd0)
														character_address = rank_game_msd_character_address;
				(TAB_MESSAGE >> 3) + 7'd6: character_address = rank_game_lsd_character_address;
				
				(TAB_MESSAGE >> 3) + 7'd16: character_address = 6'o23; // S
				(TAB_MESSAGE >> 3) + 7'd17: character_address = 6'o03; // C
				(TAB_MESSAGE >> 3) + 7'd18: character_address = 6'o17; // O
				(TAB_MESSAGE >> 3) + 7'd19: character_address = 6'o22; // R
				(TAB_MESSAGE >> 3) + 7'd20: character_address = 6'o05; // E
								
				(TAB_MESSAGE >> 3) + 7'd22: if (rank_score[7:4] != 4'd0)
														character_address = rank_score_msd_character_address;
				(TAB_MESSAGE >> 3) + 7'd23: character_address = rank_score_lsd_character_address;
			endcase
		end
		
		if (pixel_Y_pos[9:3] == (TIME_MESSAGE >> 3)) begin
				case (new_pixel_X_pos[9:3])
					(TAB_MESSAGE >> 3) + 7'd0: character_address = 6'o24; // T
					(TAB_MESSAGE >> 3) + 7'd1: character_address = 6'o11; // I
					(TAB_MESSAGE >> 3) + 7'd2: character_address = 6'o15; // M
					(TAB_MESSAGE >> 3) + 7'd3: character_address = 6'o05; // E

					(TAB_MESSAGE >> 3) + 7'd5: character_address = 6'o14; // L
					(TAB_MESSAGE >> 3) + 7'd6: character_address = 6'o05; // E
					(TAB_MESSAGE >> 3) + 7'd7: character_address = 6'o06; // F
					(TAB_MESSAGE >> 3) + 7'd8: character_address = 6'o24; // T

					(TAB_MESSAGE >> 3) + 7'd22: if (time_left[7:4] != 4'd0)
															character_address = time_left_msd_character_address;
					(TAB_MESSAGE >> 3) + 7'd23: character_address = time_left_lsd_character_address;
			endcase
		end
		
	end
end

convert_hex_to_seven_segment unit2 (
	.hex_value({2'b00, lives}), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(score[7:4]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(score[3:0]), 
	.converted_value(value_7_segment[0])
);

assign	SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
		SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
		SEVEN_SEGMENT_N_O[2] = 7'h7f,
		SEVEN_SEGMENT_N_O[3] = value_7_segment[2],
		SEVEN_SEGMENT_N_O[4] = 7'h7f,
		SEVEN_SEGMENT_N_O[5] = 7'h7f,
		SEVEN_SEGMENT_N_O[6] = 7'h7f,
		SEVEN_SEGMENT_N_O[7] = 7'h7f;

assign LED_RED_O = {system_resetn, 15'd0, object_X_direction, object_Y_direction};
assign LED_GREEN_O = {game_over, 4'd0, PB_pushed};

endmodule

