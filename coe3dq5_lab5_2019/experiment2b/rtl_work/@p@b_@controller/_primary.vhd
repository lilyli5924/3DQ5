library verilog;
use verilog.vl_types.all;
entity PB_Controller is
    port(
        Clock_50        : in     vl_logic;
        Resetn          : in     vl_logic;
        PB_signal       : in     vl_logic_vector(3 downto 0);
        PB_pushed       : out    vl_logic_vector(3 downto 0)
    );
end PB_Controller;
