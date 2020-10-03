/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

// This is the top module
module lab2_exercise (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches/push-buttons             ////////////
		input logic[17:0] SWITCH_I,               // toggle switches
		input logic[3:0] PUSH_BUTTON_I,           // pushbuttons

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs
		output logic[17:0] LED_RED_O,             // 18 red LEDs
		
		/////// PS2                               ////////////
		input logic PS2_DATA_I,                   // PS2 data
		input logic PS2_CLOCK_I,                  // PS2 clock

		/////// LCD display                       ////////////
		output logic LCD_POWER_O,                 // LCD power ON/OFF
		output logic LCD_BACK_LIGHT_O,            // LCD back light ON/OFF
		output logic LCD_READ_WRITE_O,            // LCD read/write select, 0 = Write, 1 = Read
		output logic LCD_EN_O,                    // LCD enable
		output logic LCD_COMMAND_DATA_O,          // LCD command/data select, 0 = Command, 1 = Data
		output [7:0] LCD_DATA_IO                  // LCD data bus 8 bits
);

integer i;
logic resetn;

enum logic [3:0] {
	S_LCD_INIT,
	S_LCD_INIT_WAIT,
	S_IDLE,
	S_LCD_WAIT_ROM_UPDATE,
	S_LCD_ISSUE_INSTRUCTION,
	S_LCD_FINISH_INSTRUCTION,
	S_LCD_ISSUE_CHANGE_LINE,
	S_LCD_FINISH_CHANGE_LINE,
	S_WAIT_FIVE_SECONDS,
	S_LCD_ISSUE_CLEAR_LCD,
	S_LCD_FINISH_CLEAR_LCD
} state;

logic [8:0] top_data_reg [15:0];
logic [8:0] bottom_data_reg [15:0];
logic [8:0] ROM_address;
logic [27:0] clock_monitor;
logic one_hz_clock;
logic shift_status;

logic [7:0] PS2_code;
logic PS2_code_ready, PS2_code_ready_buf;
logic PS2_make_code;

logic [2:0] LCD_init_index;
logic [8:0] LCD_init_sequence;
logic [8:0] LCD_instruction;
logic [7:0] LCD_code;
logic [3:0] LCD_position;
logic LCD_line;

logic LCD_start;
logic LCD_done;

logic [15:0] clock_1kHz_div_count;
logic clock_1kHz, clock_1kHz_buf;

logic [9:0] debounce_shift_reg [3:0];
logic [3:0] push_button_status, push_button_status_buf;

logic [3:0] PB_detected;
logic [2:0] PB_history[3:0];    // PB history of depth four
                                // 2-bits PB code / 1-bit valid
logic PB_pattern_detected;      // used to detect four consecutive PB pressings
logic LCD_clear;  	        // keeps track if the LCD has been cleared

logic [6:0] value_7_segment [7:0];

logic detect_first, detect_last; // keeps track if the first/last characters
                                 // from the bottom line have been detected in the top line
logic wait_state;                // asserted while waiting for 5 seconds
											
assign resetn = ~SWITCH_I[17];

// Clock division for 1 kHz clock
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz_div_count <= 16'h0000000;
	end else begin
		if (clock_1kHz_div_count < 'd24999) begin
			clock_1kHz_div_count <= clock_1kHz_div_count + 16'd1;
		end else 
			clock_1kHz_div_count <= 16'h0000;		
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz <= 1'b1;
	end else begin
		if (clock_1kHz_div_count == 'd0) clock_1kHz <= ~clock_1kHz;
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz_buf <= 1'b1;	
	end else begin
		clock_1kHz_buf <= clock_1kHz;
	end
end

// Shift register for debouncing the push buttons
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		debounce_shift_reg[0] <= 10'd0;
		debounce_shift_reg[1] <= 10'd0;
		debounce_shift_reg[2] <= 10'd0;
		debounce_shift_reg[3] <= 10'd0;						
	end else begin
		if (clock_1kHz_buf == 1'b0 && clock_1kHz == 1'b1) begin
			debounce_shift_reg[0] <= {debounce_shift_reg[0][8:0], ~PUSH_BUTTON_I[0]};
			debounce_shift_reg[1] <= {debounce_shift_reg[1][8:0], ~PUSH_BUTTON_I[1]};
			debounce_shift_reg[2] <= {debounce_shift_reg[2][8:0], ~PUSH_BUTTON_I[2]};
			debounce_shift_reg[3] <= {debounce_shift_reg[3][8:0], ~PUSH_BUTTON_I[3]};									
		end
	end
end

// OR gate for debouncing the push buttons
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		push_button_status <= 4'h0;
		push_button_status_buf <= 4'h0;
	end else begin
		push_button_status_buf <= push_button_status;
		push_button_status[0] <= |debounce_shift_reg[0];
		push_button_status[1] <= |debounce_shift_reg[1];
		push_button_status[2] <= |debounce_shift_reg[2];
		push_button_status[3] <= |debounce_shift_reg[3];						
	end
end

// Edge detection for push buttons
assign PB_detected = push_button_status & ~push_button_status_buf;

// keeps track of the history of push-buttons
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		PB_history[3] <= 3'b000;
		PB_history[2] <= 3'b000;
		PB_history[1] <= 3'b000;
		PB_history[0] <= 3'b000;
	end else begin
		if (|PB_detected) begin
			if (PB_detected[3]) PB_history[0] <= {1'b1,2'b11};
			if (PB_detected[2]) PB_history[0] <= {1'b1,2'b10};
			if (PB_detected[1]) PB_history[0] <= {1'b1,2'b01};
			if (PB_detected[0]) PB_history[0] <= {1'b1,2'b00};
			PB_history[1] <= PB_history[0];
			PB_history[2] <= PB_history[1];
			PB_history[3] <= PB_history[2];
		end
		if (LCD_clear) begin
			PB_history[3] <= 3'b000;
			PB_history[2] <= 3'b000;
			PB_history[1] <= 3'b000;
			PB_history[0] <= 3'b000;
		end
	end
end

assign PB_pattern_detected = (PB_history[0] == PB_history[1]) && 
                             (PB_history[0] == PB_history[2]) &&
                             (PB_history[0] == PB_history[3]) &&
                              PB_history[0][2] && (!LCD_clear);
										 
assign wait_state = (state == S_WAIT_FIVE_SECONDS);
										 
// PS2 unit
PS2_controller PS2_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	
	.PS2_clock(PS2_CLOCK_I),
	.PS2_data(PS2_DATA_I),
	
	.PS2_code(PS2_code),
	.PS2_code_ready(PS2_code_ready),
	.PS2_make_code(PS2_make_code)
);

assign ROM_address = LCD_line ? { shift_status, PS2_code } : bottom_data_reg[15];

// ROM for translate PS2 code to LCD code
PS2_to_LCD_ROM	PS2_to_LCD_ROM_inst (
	.address ( ROM_address ),
	.clock ( CLOCK_50_I ),
	.q ( LCD_code )
	);

// LCD unit
LCD_controller LCD_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.LCD_start(LCD_start),
	.LCD_instruction(LCD_instruction),
	.LCD_done(LCD_done),
	
	// LCD side
	.LCD_power(LCD_POWER_O),
	.LCD_back_light(LCD_BACK_LIGHT_O),
	.LCD_read_write(LCD_READ_WRITE_O),
	.LCD_enable(LCD_EN_O),
	.LCD_command_data_select(LCD_COMMAND_DATA_O),
	.LCD_data_io(LCD_DATA_IO)
);

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		state <= S_LCD_INIT;
		LCD_init_index <= 3'd0;
		LCD_start <= 1'b0;
		LCD_instruction <= 9'd0;
		LCD_line <= 1'b1;
		PS2_code_ready_buf <= 1'b0;
		LCD_position <= 4'h0;
		shift_status <= 1'b0;
		for (i=0; i<=15; i=i+1) begin
			top_data_reg[i] <= 9'd0;
			bottom_data_reg[i] <= 9'd0;
		end
		clock_monitor <= 28'd0;
		LCD_clear <= 1'b1;
		detect_first <= 1'b0;
		detect_last <= 1'b0;
	end else begin
	
		// used to detect if a new PS2 code has arrived
		PS2_code_ready_buf <= PS2_code_ready;
		
		case (state)
		
			S_LCD_INIT: begin
				// Initialize LCD
				///////////////////
				// DO NOT CHANGE //
				///////////////////
				LCD_instruction <= LCD_init_sequence;
				LCD_start <= 1'b1;
				state <= S_LCD_INIT_WAIT;
			end
			
			S_LCD_INIT_WAIT: begin
				///////////////////
				// DO NOT CHANGE //
				///////////////////
				if (LCD_start == 1'b1) begin
					LCD_start <= 1'b0;
				end else begin
					if (LCD_done == 1'b1) begin
						LCD_init_index <= LCD_init_index + 3'd1;
						if (LCD_init_index < 3'd4) 
							state <= S_LCD_INIT;
						else begin
							// Finish initializing LCD
							state <= S_IDLE;
							LCD_position <= 4'h0;
						end
					end
				end
			end
			
			S_IDLE: begin
				// reset the clock monitor
				clock_monitor <= 28'd0;
				LCD_clear <= 1'b0; // LCD is not clear any more
				detect_first <= 1'd0;
				detect_last <= 1'd0;
				
				// Scan code is detected
				if (PS2_code_ready && ~PS2_code_ready_buf && PS2_make_code == 1'b1) begin

					if (PS2_code == 8'h12) begin	//left shift
						shift_status <= 1'b1;
					end else if (PS2_code == 8'h59) begin	//right shift
						shift_status <= 1'b0;
					end else begin
						// Load the PS2 code to shift registers
						if (LCD_line == 1'b1) begin // top line
							top_data_reg[0] <= {shift_status, PS2_code};
							for (i=15; i>=1; i=i-1)
								top_data_reg[i] <= top_data_reg[i-1];
							state <= S_LCD_WAIT_ROM_UPDATE; 
						end else begin	
							bottom_data_reg[0] <= {shift_status, PS2_code};
							for (i=15; i>=1; i=i-1)
								bottom_data_reg[i] <= bottom_data_reg[i-1];
							if (LCD_position < 4'd15) begin
								LCD_position <= LCD_position + 4'd1;
							end else begin
								LCD_position <= 4'd0;
								state <= S_LCD_WAIT_ROM_UPDATE;
							end							
						end
					end
				end
			end
			
			S_LCD_WAIT_ROM_UPDATE: begin
				// One clock cycle to wait for ROM to update its output
				state <= S_LCD_ISSUE_INSTRUCTION;
			end
			
			S_LCD_ISSUE_INSTRUCTION: begin
				// Load translated LCD code to LCD instruction from the ROM
				LCD_instruction <= {1'b1, LCD_code};
				LCD_start <= 1'b1;
				state <= S_LCD_FINISH_INSTRUCTION;
			end

			S_LCD_FINISH_INSTRUCTION: begin
				if (LCD_start == 1'b1) begin
					LCD_start <= 1'b0;
				end else begin	
					if (LCD_done == 1'b1) begin			
						if (LCD_position < 4'd15) begin
							LCD_position <= LCD_position + 4'd1;
							if (LCD_line == 1'b1) // top line
								state <= S_IDLE;
							else begin
								state <= S_LCD_WAIT_ROM_UPDATE;
							end
						end else begin
							// Need to change line for LCD
							LCD_position <= 4'd0;
							state <= S_LCD_ISSUE_CHANGE_LINE;
						end
					end
				end
			end
			
			S_LCD_ISSUE_CHANGE_LINE: begin
				// Change line
				LCD_instruction <= {2'b01, LCD_line, 6'h00};
				LCD_line <= ~LCD_line;
				LCD_start <= 1'b1;
				state <= S_LCD_FINISH_CHANGE_LINE;
			end
			
			S_LCD_FINISH_CHANGE_LINE: begin
				if (LCD_start == 1'b1) begin
					LCD_start <= 1'b0;
				end else begin	
					if (LCD_done == 1'b1) begin	
						if (LCD_line) begin // if we are to move to the top line
							state <= S_WAIT_FIVE_SECONDS;
							clock_monitor <= 28'd249999999; // 250 million minus one
							for (i=0; i<=15; i=i+1) begin
								if (bottom_data_reg[0][7:0] == top_data_reg[i][7:0])
									detect_last <= 1'b1;
								if (bottom_data_reg[15][7:0] == top_data_reg[i][7:0])
									detect_first <= 1'b1;
							end
						end else begin 
							state <= S_IDLE;
						end
					end
				end
			end
			
			S_WAIT_FIVE_SECONDS: begin
				if (clock_monitor == 28'd0) begin
					state <= S_LCD_ISSUE_CLEAR_LCD;
				end else begin
					clock_monitor <= clock_monitor - 28'd1;
				end
			end

			S_LCD_ISSUE_CLEAR_LCD: begin
				LCD_instruction <= 9'h001;
				LCD_start <= 1'b1;
				state <= S_LCD_FINISH_CLEAR_LCD;
			end
			
			S_LCD_FINISH_CLEAR_LCD: begin
				if (LCD_start == 1'b1) begin
					LCD_start <= 1'b0;
				end else begin	
					if (LCD_done == 1'b1) begin	
						LCD_line <= 1'b1;
						PS2_code_ready_buf <= 1'b0;
						LCD_position <= 4'h0;
						shift_status <= 1'b0;
						for (i=0; i<=15; i=i+1) begin
							top_data_reg[i] <= 9'd0;
							bottom_data_reg[i] <= 9'd0;
						end
						state <= S_IDLE;
					end
				end
			end
			
			default: state <= S_LCD_INIT;
		
		endcase
		
		if (PB_pattern_detected) begin
			state <= S_LCD_ISSUE_CLEAR_LCD;
			LCD_clear <= 1'b1;
		end

	end
end

// Initialization sequence for LCD
///////////////////
// DO NOT CHANGE //
///////////////////
always_comb begin
	case(LCD_init_index)
	0:       LCD_init_sequence	=	9'h038; // Set display to be 8 bit and 2 lines
	1:       LCD_init_sequence	=	9'h00C; // Set display
	2:       LCD_init_sequence	=	9'h001; // Clear display
	3:       LCD_init_sequence	=	9'h006; // Enter entry mode
	default: LCD_init_sequence	=	9'h080; // Set starting position to 0
	endcase
end

assign LED_GREEN_O = {9{wait_state}};
assign LED_RED_O = 18'd0;

convert_hex_to_seven_segment unit7 (
	.hex_value(4'hd), 
	.converted_value(value_7_segment[7])
);

convert_hex_to_seven_segment unit6 (
	.hex_value(4'hd), 
	.converted_value(value_7_segment[6])
);

convert_hex_to_seven_segment unit4 (
	.hex_value(LCD_position), 
	.converted_value(value_7_segment[4])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(PS2_code[7:4]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(PS2_code[3:0]), 
	.converted_value(value_7_segment[0])
);

assign	SEVEN_SEGMENT_N_O[0] = 1'b1 ? 7'h7f : value_7_segment[0],
		SEVEN_SEGMENT_N_O[1] = 1'b1 ? 7'h7f : value_7_segment[1],
		SEVEN_SEGMENT_N_O[2] = 1'b1 ? 7'h7f : value_7_segment[2],
		SEVEN_SEGMENT_N_O[3] = 1'b1 ? 7'h7f : value_7_segment[3],
		SEVEN_SEGMENT_N_O[4] = 1'b1 ? 7'h7f : value_7_segment[4],
		SEVEN_SEGMENT_N_O[5] = 1'b1 ? 7'h7f : value_7_segment[5],
		SEVEN_SEGMENT_N_O[6] = !(wait_state && detect_first) ? 7'h7f : value_7_segment[6],
		SEVEN_SEGMENT_N_O[7] = !(wait_state && detect_last) ? 7'h7f : value_7_segment[7];
		
endmodule
