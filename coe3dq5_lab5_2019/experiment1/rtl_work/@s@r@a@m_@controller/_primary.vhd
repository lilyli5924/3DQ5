library verilog;
use verilog.vl_types.all;
entity SRAM_Controller is
    port(
        Clock_50        : in     vl_logic;
        Resetn          : in     vl_logic;
        SRAM_address    : in     vl_logic_vector(17 downto 0);
        SRAM_write_data : in     vl_logic_vector(15 downto 0);
        SRAM_we_n       : in     vl_logic;
        SRAM_read_data  : out    vl_logic_vector(15 downto 0);
        SRAM_ready      : out    vl_logic;
        SRAM_DATA_IO    : inout  vl_logic_vector(15 downto 0);
        SRAM_ADDRESS_O  : out    vl_logic_vector(17 downto 0);
        SRAM_UB_N_O     : out    vl_logic;
        SRAM_LB_N_O     : out    vl_logic;
        SRAM_WE_N_O     : out    vl_logic;
        SRAM_CE_N_O     : out    vl_logic;
        SRAM_OE_N_O     : out    vl_logic
    );
end SRAM_Controller;
