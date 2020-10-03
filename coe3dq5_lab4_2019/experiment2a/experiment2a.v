/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps

`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

module experiment2a (
		input logic CLOCK_I,
		input logic RESETN_I,
		output logic [8:0] ADDRESS_O,
		output logic [7:0] READ_DATA_O [1:0],
		output logic [7:0] WRITE_DATA_O [1:0],
		output logic WRITE_ENABLE_O [1:0]			
);

enum logic [1:0] {
	S_DELAY,
	S_READ,
	S_WRITE,
	S_IDLE
} state;

logic [8:0] address;
logic [7:0] write_data [1:0];
logic write_enable [1:0];
logic [7:0] read_data [1:0];

// Instantiate RAM1
single_port_RAM1 single_port_RAM_inst1 (
	.address ( address ),
	.clock ( CLOCK_I ),
	.data ( write_data[1] ),
	.wren ( write_enable[1] ),
	.q ( read_data[1] )
	);

// Instantiate RAM0
single_port_RAM0 single_port_RAM_inst0 (
	.address ( address ),
	.clock ( CLOCK_I ),
	.data ( write_data[0] ),
	.wren ( write_enable[0] ),
	.q ( read_data[0] )
	);

// The adder and substractor for the write port of the RAMs
assign write_data[0] = read_data[0] + read_data[1];
assign write_data[1] = read_data[0] - read_data[1];

// FSM to control the read and write sequence
always_ff @ (posedge CLOCK_I or negedge RESETN_I) begin
	if (RESETN_I == 1'b0) begin
		address <= 9'h000;
		write_enable[0] <= 1'b0;
		write_enable[1] <= 1'b0;		
		state <= S_DELAY;
	end else begin
		case (state)
		S_DELAY: begin	
			// One clock cycle delay for the first data		
			state <= S_READ;
		end
		S_READ: begin
			// Write data in next clock cycle
			write_enable[0] <= 1'b1;
			write_enable[1] <= 1'b1;			
			
			state <= S_WRITE;
		end
		S_WRITE: begin
			// Prepare address to read for next clock cycle
			write_enable[0] <= 1'b0;
			write_enable[1] <= 1'b0;			
		
			if (address < 9'd511) begin
				address <= address + 9'd1;

				state <= S_READ;		
			end else begin
				// Finish writing 512 addresses
				state <= S_IDLE;
			end
		end
		endcase
	end
end

assign ADDRESS_O = address;
assign READ_DATA_O = read_data;
assign WRITE_ENABLE_O = write_enable;
assign WRITE_DATA_O = write_data;

endmodule
