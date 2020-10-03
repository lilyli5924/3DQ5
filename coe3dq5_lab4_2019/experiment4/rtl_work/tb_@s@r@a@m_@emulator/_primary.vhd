library verilog;
use verilog.vl_types.all;
entity tb_SRAM_Emulator is
    generic(
        SRAM_SIZE       : integer := 262144
    );
    port(
        Clock_50        : in     vl_logic;
        Resetn          : in     vl_logic;
        SRAM_data_io    : inout  vl_logic_vector(15 downto 0);
        SRAM_address    : in     vl_logic_vector(17 downto 0);
        SRAM_UB_N       : in     vl_logic;
        SRAM_LB_N       : in     vl_logic;
        SRAM_WE_N       : in     vl_logic;
        SRAM_CE_N       : in     vl_logic;
        SRAM_OE_N       : in     vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of SRAM_SIZE : constant is 1;
end tb_SRAM_Emulator;
