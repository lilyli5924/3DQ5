/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

// This is the top module
// This module connects the UART receiver and transmitter together
module experiment3 (
		/////// board clocks                      ////////////
		input logic CLOCK_27_I,                   // 27 MHz clock		
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_I,           // pushbuttons		
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs

		/////// UART                              ////////////
		input logic UART_RX_I,                    // UART receive signal
		output logic UART_TX_O,                   // UART transmit signal
		
		/////// TD_RESET                          ////////////
		output logic TD_RESET_N                   // Signal to enable 27MHz clock
);

assign	TD_RESET_N = 1'b1; // Enable 27 MHz clock

logic resetn;

logic switch_0_buf, switch_1_buf;

// For 7-segment displays
logic [6:0] value_7_segment [5:0];

// For UART receiver
logic UART_rx_enable;
logic UART_rx_unload_data;
logic [7:0] UART_rx_data;
logic UART_rx_empty;
logic UART_rx_over_run;
logic UART_rx_frame_error;
logic UART_rx_done;
logic [2:0] over_run_count, error_count;

// For UART tramsitter
logic UART_tx_start;
logic UART_tx_empty;
logic UART_tx_done;
logic [8:0] UART_tx_address;

// For the dual port RAM
logic [8:0] UART_rx_address;
logic [7:0] UART_write_data;
logic [7:0] UART_read_data;
logic UART_we;

RX_state_type RX_state;
TX_state_type TX_state;

assign resetn = ~SWITCH_I[17];

logic Clock_57_6;
logic UART_tx_clock, UART_tx_clock_buf;
logic [7:0] UART_tx_clock_div;
logic UART_tx_clock_enable;

// PLL for generating a 57.6 MHz clock
UART_clock	UART_clock_inst (
	.areset ( ~resetn ),
	.inclk0 ( CLOCK_27_I ),
	.c0 ( Clock_57_6 )
);

// Divide the 57.6 MHz clock to 115.2 kHz for transmitting at 115.2 kbps
always_ff @ (posedge Clock_57_6 or negedge resetn) begin
	if (!resetn) begin
		UART_tx_clock_div <= 8'h00;
		UART_tx_clock <= 1'b0;
		UART_tx_clock_buf <= 1'b0;
	end else begin
		if (UART_tx_clock_div < 8'd249) begin
			UART_tx_clock_div <= UART_tx_clock_div + 8'h01;		
		end else begin
			UART_tx_clock_div <= 8'h00;
			UART_tx_clock <= ~UART_tx_clock;
		end
		UART_tx_clock_buf <= UART_tx_clock;
	end
end

assign UART_tx_clock_enable = UART_tx_clock & ~UART_tx_clock_buf;

// RAM for storing received UART data
dual_port_RAM dual_port_RAM_inst (
	.address_a ( UART_rx_address ),
	.address_b ( UART_tx_address ),
	.clock ( CLOCK_50_I ),
	.data_a ( UART_write_data ),
	.data_b ( 8'h00 ),
	.wren_a ( UART_we ),
	.wren_b ( 1'b0 ),
	.q_a (  ),
	.q_b ( UART_read_data )
	);

// UART_Receiver
UART_Receive_Controller UART_RX (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	
	.Enable(UART_rx_enable),
	.Unload_data(UART_rx_unload_data),
	.RX_data(UART_rx_data),
	.Empty(UART_rx_empty),
	.Overrun(UART_rx_over_run),
	.Frame_error(UART_rx_frame_error),
	
	// UART pin
	.UART_RX_I(UART_RX_I)
);

// UART_Transmitter
UART_Transmit_Controller UART_TX (
	.Clock(Clock_57_6),
	.TX_clock_enable(UART_tx_clock_enable),
	.Resetn(resetn),
	
	.Start(UART_tx_start),
	.TX_data(UART_read_data),
	.Empty(UART_tx_empty),

	// UART pin
	.UART_TX_O(UART_TX_O)
);

convert_hex_to_seven_segment unit5 (
	.hex_value({3'b0, UART_tx_address[8]}), 
	.converted_value(value_7_segment[5])
);

convert_hex_to_seven_segment unit4 (
	.hex_value(UART_tx_address[7:4]), 
	.converted_value(value_7_segment[4])
);

convert_hex_to_seven_segment unit3 (
	.hex_value(UART_tx_address[3:0]), 
	.converted_value(value_7_segment[3])
);

convert_hex_to_seven_segment unit2 (
	.hex_value({3'b0, UART_rx_address[8]}), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(UART_rx_address[7:4]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(UART_rx_address[3:0]), 
	.converted_value(value_7_segment[0])
);
// FSM for receiving
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		UART_rx_address <= 9'd0;
		UART_write_data <= 8'd0;
		UART_we <= 1'b0;

		UART_rx_enable <= 1'b0;
		UART_rx_done <= 1'b1;
		UART_rx_unload_data <= 1'b0;

		RX_state <= S_RX_IDLE;	
		
		switch_0_buf <= 1'b0;
	end else begin
		switch_0_buf <= SWITCH_I[0];
		
		case (RX_state) 
		S_RX_IDLE: begin
			if (SWITCH_I[0] & ~switch_0_buf) begin
				UART_rx_address <= 9'd0;
				RX_state <= S_RX_START_RECEIVE;
				UART_rx_enable <= 1'b1;
				UART_rx_done <= 1'b0;
			end
		end
		S_RX_START_RECEIVE: begin
			if (UART_rx_empty == 1'b0) begin
				// a byte of data is available
				UART_rx_unload_data <= 1'b1;

				// Write the data into the RAM
				UART_write_data <= UART_rx_data;
				UART_we <= 1'b1;
				
				RX_state <= S_RX_WRITE_RECEIVED_DATA;				
			end
		end
		S_RX_WRITE_RECEIVED_DATA: begin
			UART_we <= 1'b0;
			if (UART_rx_empty == 1'b1) begin
				// Clear the unload flag
				UART_rx_unload_data <= 1'b0;
				
				if (UART_rx_address < 9'h1FF) begin
					UART_rx_address <= UART_rx_address + 9'd1;
					RX_state <= S_RX_START_RECEIVE;
				end else begin
					// Finish receiving 512 bytes of data
					RX_state <= S_RX_IDLE;
					
					UART_rx_enable <= 1'b0;					
					UART_rx_done <= 1'b1;
				end
			end
		end
		default: RX_state <= S_RX_IDLE;
		endcase
	end
end

// Counting the number of error in UART receiver
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (!resetn) begin
		error_count <= 3'h0;
		over_run_count <= 3'h0;
	end else begin
		if (UART_rx_over_run) over_run_count <= over_run_count + 3'h1;
		if (UART_rx_frame_error) error_count <= error_count + 3'h1;
	end
end

// FSM for transmitting
always_ff @ (posedge Clock_57_6 or negedge resetn) begin
	if (resetn == 1'b0) begin
		UART_tx_address <= 9'd0;
		UART_tx_start <= 1'b0;
		UART_tx_done <= 1'b1;
		
		TX_state <= S_TX_IDLE;
		
		switch_1_buf <= 1'b0;
	end else begin
		if (UART_tx_clock_enable) begin
		
			switch_1_buf <= SWITCH_I[1];
			
			case (TX_state)
			S_TX_IDLE: begin
				if (SWITCH_I[1] & ~switch_1_buf) begin
					UART_tx_address <= 9'd0;
					TX_state <= S_TX_START_TRANSMIT;
					
					UART_tx_done <= 1'b0;
				end			
			end
			S_TX_START_TRANSMIT: begin
				// Start sending the first byte of data
				if (UART_tx_empty == 1'b1) begin
					UART_tx_start <= 1'b1;								

					TX_state <= S_TX_TRANSMIT_DATA;
				end
			end
			S_TX_TRANSMIT_DATA: begin
				// Start the transfer
				if (UART_tx_empty == 1'b0) begin
					// The start is accepted by the UART_Transmitter_Controller
					UART_tx_start <= 1'b0;

					// Provide address for next data in RAM
					UART_tx_address <= UART_tx_address + 9'd1;
									
					TX_state <= S_TX_WAIT_TRANSMIT;
				end
			end
			S_TX_WAIT_TRANSMIT: begin
				// Wait for transfer to finish
				if (UART_tx_empty == 1'b1) begin			
					if (UART_tx_address != 9'd0) begin
						// Continue sending
						UART_tx_start <= 1'b1;				

						TX_state <= S_TX_TRANSMIT_DATA;
					end else begin
						// Finish sending 512 bytes
						TX_state <= S_TX_IDLE;
						
						UART_tx_done <= 1'b1;
					end
				end
			end
			default: TX_state <= S_TX_IDLE;
			endcase
		end
	end
end

assign	SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
		SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
		SEVEN_SEGMENT_N_O[2] = value_7_segment[2],
		SEVEN_SEGMENT_N_O[3] = 7'h7f,
		SEVEN_SEGMENT_N_O[4] = value_7_segment[3],
		SEVEN_SEGMENT_N_O[5] = value_7_segment[4],
		SEVEN_SEGMENT_N_O[6] = value_7_segment[5],
		SEVEN_SEGMENT_N_O[7] = 7'h7f;

assign LED_GREEN_O = {1'b0, UART_tx_done, over_run_count, error_count, UART_rx_done};
		
endmodule
