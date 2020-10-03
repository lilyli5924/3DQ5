library verilog;
use verilog.vl_types.all;
entity experiment2b is
    generic(
        NUM_ROW_RECTANGLE: integer := 8;
        NUM_COL_RECTANGLE: integer := 8;
        RECT_WIDTH      : integer := 40;
        RECT_HEIGHT     : integer := 30;
        VIEW_AREA_LEFT  : integer := 160;
        VIEW_AREA_RIGHT : integer := 480;
        VIEW_AREA_TOP   : integer := 120;
        VIEW_AREA_BOTTOM: integer := 360
    );
    port(
        CLOCK_50_I      : in     vl_logic;
        PUSH_BUTTON_I   : in     vl_logic_vector(3 downto 0);
        SWITCH_I        : in     vl_logic_vector(17 downto 0);
        VGA_CLOCK_O     : out    vl_logic;
        VGA_HSYNC_O     : out    vl_logic;
        VGA_VSYNC_O     : out    vl_logic;
        VGA_BLANK_O     : out    vl_logic;
        VGA_SYNC_O      : out    vl_logic;
        VGA_RED_O       : out    vl_logic_vector(7 downto 0);
        VGA_GREEN_O     : out    vl_logic_vector(7 downto 0);
        VGA_BLUE_O      : out    vl_logic_vector(7 downto 0);
        SRAM_DATA_IO    : inout  vl_logic_vector(15 downto 0);
        SRAM_ADDRESS_O  : out    vl_logic_vector(19 downto 0);
        SRAM_UB_N_O     : out    vl_logic;
        SRAM_LB_N_O     : out    vl_logic;
        SRAM_WE_N_O     : out    vl_logic;
        SRAM_CE_N_O     : out    vl_logic;
        SRAM_OE_N_O     : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of NUM_ROW_RECTANGLE : constant is 1;
    attribute mti_svvh_generic_type of NUM_COL_RECTANGLE : constant is 1;
    attribute mti_svvh_generic_type of RECT_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of RECT_HEIGHT : constant is 1;
    attribute mti_svvh_generic_type of VIEW_AREA_LEFT : constant is 1;
    attribute mti_svvh_generic_type of VIEW_AREA_RIGHT : constant is 1;
    attribute mti_svvh_generic_type of VIEW_AREA_TOP : constant is 1;
    attribute mti_svvh_generic_type of VIEW_AREA_BOTTOM : constant is 1;
end experiment2b;
