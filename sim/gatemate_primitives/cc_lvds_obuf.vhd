library sim;
context sim.sim_context;

entity CC_LVDS_OBUF is
    generic (
        PIN_NAME_P  : string := "UNPLACED";   -- IO_<Dir><Bank>_<Pin><Pin#>
        PIN_NAME_N  : string := "UNPLACED";   -- secondary diff. signal
        V_IO        : string := "UNDEFINED";  -- "1.8" or "2.5" Volt
        LVDS_BOOST  : integer := 0;           -- 0: 3.2 mA, 1: 6.4 mA
        DELAY_OBF   : integer := 0;           -- input delay: 0..15
        FF_OBF      : integer := 0            -- 0: disable, 1: enable
    );
    port (
        A: in  std_ulogic;
        O_P: out  std_ulogic;
        O_N: out  std_ulogic
    );
end entity;

architecture sim of CC_LVDS_OBUF is
begin
    O_P <= A;
    O_N <= not A;
end sim;