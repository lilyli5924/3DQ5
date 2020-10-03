library verilog;
use verilog.vl_types.all;
entity SRAM_BIST is
    port(
        Clock           : in     vl_logic;
        Resetn          : in     vl_logic;
        BIST_start      : in     vl_logic;
        BIST_address    : out    vl_logic_vector(17 downto 0);
        BIST_write_data : out    vl_logic_vector(15 downto 0);
        BIST_we_n       : out    vl_logic;
        BIST_read_data  : in     vl_logic_vector(15 downto 0);
        BIST_finish     : out    vl_logic;
        BIST_mismatch   : out    vl_logic
    );
end SRAM_BIST;
