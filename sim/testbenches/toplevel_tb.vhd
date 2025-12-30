library sim;
context sim.sim_context;

-- Toplevel entitity of the design
entity toplevel_tb is
end toplevel_tb;

architecture rtl of toplevel_tb is
    signal ref_clk: std_ulogic;
    signal led: std_ulogic;

    component toplevel is
        port (
            ref_clk: in std_ulogic;
            led: out std_ulogic
        );
    end component;
begin
    clock(ref_clk, 25e6); -- 25 MHz reference clock

    dut: component toplevel
        port map(
            ref_clk => ref_clk,
            led => led
        );
end rtl;
