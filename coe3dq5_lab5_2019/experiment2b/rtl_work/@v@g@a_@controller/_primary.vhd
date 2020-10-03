library verilog;
use verilog.vl_types.all;
entity VGA_Controller is
    generic(
        H_SYNC_CYC      : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0);
        H_SYNC_BACK     : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0);
        H_SYNC_ACT      : vl_logic_vector(0 to 9) := (Hi1, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0);
        H_SYNC_TOTAL    : vl_logic_vector(0 to 9) := (Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0);
        V_SYNC_CYC      : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0);
        V_SYNC_BACK     : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi1, Hi1, Hi1);
        V_SYNC_ACT      : vl_logic_vector(0 to 9) := (Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0);
        V_SYNC_TOTAL    : vl_logic_vector(0 to 9) := (Hi1, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0);
        X_START         : vl_notype;
        Y_START         : vl_notype
    );
    port(
        Clock           : in     vl_logic;
        Resetn          : in     vl_logic;
        iRed            : in     vl_logic_vector(9 downto 0);
        iGreen          : in     vl_logic_vector(9 downto 0);
        iBlue           : in     vl_logic_vector(9 downto 0);
        oCoord_X        : out    vl_logic_vector(9 downto 0);
        oCoord_Y        : out    vl_logic_vector(9 downto 0);
        oVGA_R          : out    vl_logic_vector(9 downto 0);
        oVGA_G          : out    vl_logic_vector(9 downto 0);
        oVGA_B          : out    vl_logic_vector(9 downto 0);
        oVGA_H_SYNC     : out    vl_logic;
        oVGA_V_SYNC     : out    vl_logic;
        oVGA_SYNC       : out    vl_logic;
        oVGA_BLANK      : out    vl_logic;
        oVGA_CLOCK      : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of H_SYNC_CYC : constant is 1;
    attribute mti_svvh_generic_type of H_SYNC_BACK : constant is 1;
    attribute mti_svvh_generic_type of H_SYNC_ACT : constant is 1;
    attribute mti_svvh_generic_type of H_SYNC_TOTAL : constant is 1;
    attribute mti_svvh_generic_type of V_SYNC_CYC : constant is 1;
    attribute mti_svvh_generic_type of V_SYNC_BACK : constant is 1;
    attribute mti_svvh_generic_type of V_SYNC_ACT : constant is 1;
    attribute mti_svvh_generic_type of V_SYNC_TOTAL : constant is 1;
    attribute mti_svvh_generic_type of X_START : constant is 3;
    attribute mti_svvh_generic_type of Y_START : constant is 3;
end VGA_Controller;
