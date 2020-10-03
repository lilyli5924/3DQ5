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
// It utilizes a priority encoder to detect a 1 on the MSB for switches 17 downto 0
// It then displays the switch number onto the 7-segment display
module experiment2 (
		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		//logic[6:0] SEVEN_SEGMENT_N_O[7:0] is a 2D array[7][8]
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs
		output logic[17:0] LED_RED_O              // 18 red LEDs
);

logic [3:0] value_bit0;
logic [3:0] value_bit1;
logic [6:0] value_7_segment_bit0;
logic [6:0] value_7_segment_bit1;

// Instantiate a module for converting hex number to 7-bit value for the 7-segment display
// Instantiating another module convert_hex_to_seven_segment
convert_hex_to_seven_segment unit0 (
	.hex_value(value_bit0), 
	.converted_value(value_7_segment_bit0)
);

convert_hex_to_seven_segment unit1 (
	.hex_value(value_bit1), 
	.converted_value(value_7_segment_bit1)
);

// A priority encoder using if-else statement
always_comb begin
	if (SWITCH_I[12] == 1'b1) begin
		value_bit0 = 4'd2;
		value_bit1 = 4'd1;
	end else begin
	if (SWITCH_I[11] == 1'b1) begin
		value_bit0 = 4'd1;
		value_bit1 = 4'd1;
	end else begin
	if (SWITCH_I[10] == 1'b1) begin
		value_bit0 = 4'd0;
		value_bit1 = 4'd1;
	end else begin
	if (SWITCH_I[9] == 1'b1) begin
		value_bit0 = 4'd9;
		value_bit1 = 4'd0;
	end else begin
		if (SWITCH_I[8] == 1'b1) begin
			value_bit0 = 4'd8;
			value_bit1 = 4'd0;
		end else begin
			if (SWITCH_I[7] == 1'b1) begin
				value_bit0 = 4'd7;
				value_bit1 = 4'd0;
			end else begin
				if (SWITCH_I[6] == 1'b1) begin
					value_bit0 = 4'd6;
					value_bit1 = 4'd0;
				end else begin
					if (SWITCH_I[5] == 1'b1) begin
						value_bit0 = 4'd5;
						value_bit1 = 4'd0;
					end else begin
						if (SWITCH_I[4] == 1'b1) begin
							value_bit0 = 4'd4;
							value_bit1 = 4'd0;
						end else begin
							if (SWITCH_I[3] == 1'b1) begin
								value_bit0 = 4'd3;
								value_bit1 = 4'd0;
							end else begin
								if (SWITCH_I[2] == 1'b1) begin
									value_bit0 = 4'd2;
									value_bit1 = 4'd0;
								end else begin
									if (SWITCH_I[1] == 1'b1) begin
										value_bit0 = 4'd1;
										value_bit1 = 4'd0;
									end else begin
										if (SWITCH_I[0] == 1'b1) begin
											value_bit0 = 4'd0;
											value_bit1 = 4'd0;
										end else begin
											value_bit0 = 4'hF;
											value_bit1 = 4'd0;
										end
										end
										end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

assign  SEVEN_SEGMENT_N_O[0] = value_7_segment_bit0,
        SEVEN_SEGMENT_N_O[1] = value_7_segment_bit1,
        SEVEN_SEGMENT_N_O[2] = 7'h7f,
        SEVEN_SEGMENT_N_O[3] = 7'h7f,
        SEVEN_SEGMENT_N_O[4] = 7'h7f,
        SEVEN_SEGMENT_N_O[5] = 7'h7f,
        SEVEN_SEGMENT_N_O[6] = 7'h7f,
        SEVEN_SEGMENT_N_O[7] = 7'h7f;

assign LED_RED_O = SWITCH_I;
//LED_GREEN_O = {5'h00, value};, where 5'h00 takes 5 bits and value takes the
//rest of the 4 bits
assign LED_GREEN_O = {1'h00, value_bit1, value_bit0};
	
endmodule
