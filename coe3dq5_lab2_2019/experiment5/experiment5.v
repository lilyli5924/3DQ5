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
// It connects the PS2 controller and the LCD controller
// It first stores the typed keys onto 4 data registers
// When the data registers are full, it will update the LCD with the 4 new characters
module experiment5 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

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

logic resetn;

enum logic [3:0] {
	S_LCD_INIT,
	S_LCD_INIT_WAIT,
	S_IDLE,
	S_LCD_WAIT_ROM_UPDATE,
	S_LCD_ISSUE_INSTRUCTION,
	S_LCD_FINISH_INSTRUCTION,
	S_LCD_ISSUE_CHANGE_LINE,
	S_LCD_FINISH_CHANGE_LINE
} state;

logic [3:0] data_counter;

logic [7:0] data_reg [15:0];

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

logic [6:0] value_7_segment[2:0];

assign resetn = ~SWITCH_I[17];

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

// ROM for translate PS2 code to LCD code
PS2_to_LCD_ROM	PS2_to_LCD_ROM_inst (
	.address ( {1'b0, data_reg[15]} ),
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
		data_counter <= 4'd0;
		data_reg[15] <= 8'h00;
		data_reg[14] <= 8'h00;
		data_reg[13] <= 8'h00;
		data_reg[12] <= 8'h00;
		data_reg[11] <= 8'h00;
		data_reg[10] <= 8'h00;
		data_reg[9] <= 8'h00;
		data_reg[8] <= 8'h00;
		data_reg[7] <= 8'h00;
		data_reg[6] <= 8'h00;
		data_reg[5] <= 8'h00;
		data_reg[4] <= 8'h00;
		data_reg[3] <= 8'h00;
		data_reg[2] <= 8'h00;
		data_reg[1] <= 8'h00;
		data_reg[0] <= 8'h00;		
	end else begin
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
			// Scan code is detected
			if (PS2_code_ready && ~PS2_code_ready_buf && PS2_make_code == 1'b1) begin
				// For this case does not need buffer register since the first line 
				// gets letter every time type the key?
				// Refer to experiment4? 
				// data_reg[15] <= PS2_code;
				if (data_counter < 4'd15) begin
					data_counter <= data_counter + 4'd1;
				end else begin
					// Send the 4 data to LCD
					data_counter <= 4'd0;
					state <= S_LCD_WAIT_ROM_UPDATE;
				end
				// Load the PS2 code to shift registers (?)
				data_reg[15] <= data_reg[14];
				data_reg[14] <= data_reg[13];
				data_reg[13] <= data_reg[12];
				data_reg[12] <= data_reg[11];
				data_reg[10] <= data_reg[9];
				data_reg[9]  <= data_reg[8];
				data_reg[8]  <= data_reg[7];
				data_reg[7]  <= data_reg[6];
				data_reg[6]  <= data_reg[5];
				data_reg[5]  <= data_reg[4];
				data_reg[4]  <= data_reg[3];
				data_reg[3]  <= data_reg[2];
				data_reg[2]  <= data_reg[1];
				data_reg[1]  <= data_reg[0];
				data_reg[0]  <= PS2_code;
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
				if (LCD_done == 1'b1) begin	LCD_position		
					if (LCD_position < 4'd15) begin
						LCD_position <=  + 4'h1;
						if (data_counter < 4'd15) begin
							data_counter <= data_counter + 4'd1;

							state <= S_LCD_WAIT_ROM_UPDATE;
						end else begin
							data_counter <= 4'd0;						

							state <= S_IDLE;
						end
					end else begin
						// Need to change to line 2 for LCD
						LCD_position <= 4'h0;
						state <= S_LCD_ISSUE_CHANGE_LINE;
					end
					data_reg[15] <= data_reg[14];
					data_reg[14] <= data_reg[13];
					data_reg[13] <= data_reg[12];
					data_reg[12] <= data_reg[11];
					data_reg[10] <= data_reg[9];
					data_reg[9]  <= data_reg[8];
					data_reg[8]  <= data_reg[7];
					data_reg[7]  <= data_reg[6];
					data_reg[6]  <= data_reg[5];
					data_reg[5]  <= data_reg[4];
					data_reg[4]  <= data_reg[3];
					data_reg[3]  <= data_reg[2];
					data_reg[2]  <= data_reg[1];
					data_reg[1]  <= data_reg[0];
					data_reg[0]  <= 8'h00;					
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
					if (data_counter < 4'd15) begin
						data_counter <= data_counter + 4'd1;
							
						state <= S_LCD_WAIT_ROM_UPDATE;
					end else begin
						// finish displaying
						data_counter <= 4'd0;
						
						//state <= S_DELAY;
						state <= S_IDLE;
					end
				end
			end
		end
//		S_DELAY: begin
//			if (LED_delay < 18'hxxxxx) begin
//				LED_delay <= LED_delay + 18'd1;
//				led_up    <= 1'b1;
//			end else begin
//				LED_delay 		<= 18'd0;
//				LCD_instruction <= 9'h001;
//				led_up    		<= 1'b0;
//				state 			<= S_IDLE;
//			end
//		end
		default: state <= S_LCD_INIT;
		endcase
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

assign LED_GREEN_O = LCD_instruction;
assign LED_RED_O = {resetn, 16'd0, PS2_make_code};

convert_hex_to_seven_segment unit2 (
	.hex_value({2'b00, data_counter}), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(PS2_code[7:4]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(PS2_code[3:0]), 
	.converted_value(value_7_segment[0])
);

//assign SEVEN_SEGMENT_N_O[0] = (led_up) ? 8'hff : value_7_segment[0];
assign	SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
		SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
		SEVEN_SEGMENT_N_O[2] = 7'h7f,
		SEVEN_SEGMENT_N_O[3] = 7'h7f,
		SEVEN_SEGMENT_N_O[4] = value_7_segment[2],
		SEVEN_SEGMENT_N_O[5] = 7'h7f,
		SEVEN_SEGMENT_N_O[6] = 7'h7f,
		SEVEN_SEGMENT_N_O[7] = 7'h7f;
		
endmodule
