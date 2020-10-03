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
// It divides the 50 MHz clock into a 1 Hz clock
// Number of fast clock pulses that makes up 1 clock period of a slow clock (W)
// W = (fast freq.)/(slow freq.) = 50000000/1 = 50000000
// Since only half period is needed to detect edge:
// W = 50000000/2 = 25000000
// It then uses edge detection and pulse generation for incrementing a counter every second
module experiment4 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs
		output logic[17:0] LED_RED_O              // 18 red LEDs
);

logic resetn;
logic [24:0] clock_div_count;
logic one_sec_clock, one_sec_clock_buf;

logic count_enable;
logic [7:0] counter;

logic [6:0] value_7_segment0, value_7_segment1;

//Use the MSB of switch as active low reset
assign resetn = ~SWITCH_I[17];

// A counter for clock division
//Sequential logic here: = process(CLK) in VHDL
//posedge: rising_edge(CLK)
//negedge: falling_edge(CLK)
//Divide 50MHz into 1Hz
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_div_count <= 25'h0000000;
	end else begin
		if (clock_div_count < 'd24999999) begin
			clock_div_count <= clock_div_count + 25'd1;
		end else 
			clock_div_count <= 25'h0000000;		
	end
end

// The value of one_sec_clock flip-flop is inverted every time the clock division logic is reset to zero
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		one_sec_clock <= 1'b1;
	end else begin
		if (clock_div_count == 'd0) one_sec_clock <= ~one_sec_clock;
	end
end

// A buffer on one_sec_clock for edge detection, one clock cycle delay than
// one_sec_clock
// Shift register here: 
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		one_sec_clock_buf <= 1'b1;	
	end else begin
		one_sec_clock_buf <= one_sec_clock;
	end
end

// Pulse generation, that generates one pulse every time a posedge is detected on one_sec_clock, it follows 1 Hz clock edge
// This logic operator && will return true (1'b1) if AND two
assign count_enable_pos = (one_sec_clock_buf == 1'b0 && one_sec_clock == 1'b1);
// Flip the two input will trigger the fall edge of this pulse
assign count_enable_neg = (one_sec_clock_buf == 1'b1 && one_sec_clock == 1'b0);

// A counter that increments every second
// If either resset is pressed or counter value reaches 59, reset counter value to 0
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0 | counter == 8'd59) begin
		counter <= 8'd0;
	end else begin
		//Trigger both positive edge and negative edge of the pulse to achieve the fact that count at half of the clock period
		if (count_enable_pos == 1'b1 | count_enable_neg == 1'b1) begin
			counter <= counter + 8'd1;
		end
	end
end

// Instantiate modules for converting hex number to 7-bit value for the 7-segment display
convert_hex_to_seven_segment unit0 (
	.hex_value(counter[3:0]), 
	.converted_value(value_7_segment0)
);

convert_hex_to_seven_segment unit1 (
	.hex_value(counter[7:4]), 
	.converted_value(value_7_segment1)
);

//Takes 2 7-bit segment to display a double digit number in base 10
assign	SEVEN_SEGMENT_N_O[0] = value_7_segment0,
		SEVEN_SEGMENT_N_O[1] = value_7_segment1,
		SEVEN_SEGMENT_N_O[2] = 7'h7f,
		SEVEN_SEGMENT_N_O[3] = 7'h7f,
		SEVEN_SEGMENT_N_O[4] = 7'h7f,
		SEVEN_SEGMENT_N_O[5] = 7'h7f,
		SEVEN_SEGMENT_N_O[6] = 7'h7f,
		SEVEN_SEGMENT_N_O[7] = 7'h7f;
		
assign LED_RED_O = SWITCH_I;
assign LED_GREEN_O = {1'b0, counter};
endmodule
