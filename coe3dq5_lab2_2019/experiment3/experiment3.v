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
// It uses a LCD_Controller to display a message on the LCD screen
module experiment3 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// LEDs                              ////////////
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs
		output logic[17:0] LED_RED_O,             // 18 red LEDs
		
		/////// LCD display                       ////////////
		output logic LCD_POWER_O,                 // LCD power ON/OFF
		output logic LCD_BACK_LIGHT_O,            // LCD back light ON/OFF
		output logic LCD_READ_WRITE_O,            // LCD read/write select, 0 = Write, 1 = Read
		output logic LCD_EN_O,                    // LCD enable
		output logic LCD_COMMAND_DATA_O,          // LCD command/data select, 0 = Command, 1 = Data
		output [7:0] LCD_DATA_IO                  // LCD data bus 8 bits
);

enum logic [2:0] {
	S_LCD_INIT,
	S_LCD_INIT_WAIT,
	S_IDLE,
	S_LCD_ISSUE_INSTRUCTION,
	S_LCD_FINISH_INSTRUCTION
} state;

logic resetn;

logic [2:0] LCD_init_index;
logic [5:0] LCD_data_index;
logic [8:0] LCD_init_sequence, LCD_data_sequence;
logic [8:0] LCD_instruction;
logic switch_0_buf;

logic LCD_start;
logic LCD_done;

assign resetn = ~SWITCH_I[17];

// LCD Controller
LCD_controller unit0 (
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

// This FSM reads the LCD instruction for the defined message and issues them onto the LCD controller
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		state <= S_LCD_INIT;
		LCD_init_index <= 3'd0;
		LCD_start <= 1'b0;
		LCD_instruction <= 9'd0;
		LCD_data_index <= 6'd0;
		switch_0_buf <= 1'b0;		
	end else begin
		switch_0_buf <= SWITCH_I[0];
			
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
					end
				end
			end
		end
		S_IDLE: begin
			if (SWITCH_I[0] != switch_0_buf) begin
				// Switch 0 is flipped, update the LCD display
				LCD_data_index <= 6'd0;			
				state <= S_LCD_ISSUE_INSTRUCTION;
			end
		end
		S_LCD_ISSUE_INSTRUCTION: begin
			// Start issuing instruction to LCD for displaying characters
			LCD_instruction <= LCD_data_sequence;
			LCD_start <= 1'b1;
			state <= S_LCD_FINISH_INSTRUCTION;
		end
		S_LCD_FINISH_INSTRUCTION: begin
			if (LCD_start == 1'b1) begin
				LCD_start <= 1'b0;
			end else begin	
				if (LCD_done == 1'b1) begin			
					if (LCD_data_index < 6'd33) begin
						LCD_data_index <= LCD_data_index + 6'd1;					
						state <= S_LCD_ISSUE_INSTRUCTION;
					end else begin
						// Finish updating all the 32 digits on the LCD
						state <= S_IDLE;
					end
				end
			end
		end
		default: state <= S_IDLE;
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

// Look-up table for LCD instructions
always_comb begin
	case (LCD_data_index)

	0:  LCD_data_sequence	=	9'h080; // Set starting position to 0
	//	Line 1
	1:	LCD_data_sequence	=	9'h157; // W
	2:	LCD_data_sequence	=	9'h165; // e
	3:	LCD_data_sequence	=	9'h16C; // l
	4:	LCD_data_sequence	=	9'h163; // c
	5:	LCD_data_sequence	=	9'h16F; // o
	6:	LCD_data_sequence	=	9'h16D; // m
	7:	LCD_data_sequence	=	9'h165; // e
	8:	LCD_data_sequence	=	9'h120; // 
	9:	LCD_data_sequence	=	9'h174; // t
	10:	LCD_data_sequence	=	9'h16F; // o
	11:	LCD_data_sequence	=	9'h120; // 
	12:	LCD_data_sequence	=	9'h133; // 3
	13:	LCD_data_sequence	=	9'h144; // D
	14:	LCD_data_sequence	=	9'h151; // Q
	15:	LCD_data_sequence	=	9'h135; // 5
	16:	LCD_data_sequence	=	9'h120; //  
	//	Change Line
	17:	LCD_data_sequence	=	9'h0C0;
	//	Line 2
	18:	LCD_data_sequence	=	9'h14C; // L
	19:	LCD_data_sequence	=	9'h161; // a
	20:	LCD_data_sequence	=	9'h162; // b
	21:	LCD_data_sequence	=	9'h12E; // .    
	22:	LCD_data_sequence	=	9'h132; // 2
	23:	LCD_data_sequence	=	9'h120; // 
	24:	LCD_data_sequence	=	9'h145; // E
	25:	LCD_data_sequence	=	9'h178; // x
	26:	LCD_data_sequence	=	9'h170; // p
	27:	LCD_data_sequence	=	9'h12e; // .
	28:	LCD_data_sequence	=	9'h133; // 3
	29:	LCD_data_sequence	=	9'h13A; // :
	30:	LCD_data_sequence	=	9'h120; //  
	31:	LCD_data_sequence	=	9'h14C; // L
	32:	LCD_data_sequence	=	9'h143; // C
//	33:	LCD_data_sequence	=	9'h144; // D
	default:	LCD_data_sequence	=	9'h144;
	endcase
end

assign LED_GREEN_O = LCD_instruction;
assign LED_RED_O = {resetn, state, LCD_init_index, LCD_data_index, LCD_start, LCD_done, 3'd0};

endmodule