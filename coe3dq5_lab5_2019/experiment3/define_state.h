`ifndef DEFINE_STATE

// This defines the states

typedef enum logic [1:0] {
	S_RX_IDLE,
	S_RX_START_RECEIVE,
	S_RX_WRITE_RECEIVED_DATA
} RX_state_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [1:0] {
	S_TX_IDLE,
	S_TX_START_TRANSMIT,
	S_TX_TRANSMIT_DATA,
	S_TX_WAIT_TRANSMIT
} TX_state_type;

typedef enum logic [1:0] {
	S_TXC_IDLE,
	S_TXC_START_BIT,
	S_TXC_DATA,
	S_TXC_STOP_BIT
} TX_Controller_state_type;


`define DEFINE_STATE 1
`endif
