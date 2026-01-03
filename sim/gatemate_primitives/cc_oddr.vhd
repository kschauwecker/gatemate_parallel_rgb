library sim;
context sim.sim_context;

entity CC_ODDR is
    generic (
        CLK_INV: integer := 0 -- 0: rising edge, 1: falling edge
    );
    port (
        D0: in std_ulogic;
        D1: in std_ulogic;
        CLK: in std_ulogic;
        DDR: in std_ulogic;
        Q: out std_ulogic
    );
end entity;

architecture sim of CC_ODDR is
    signal ff_d0: std_ulogic := '0';
    signal ff_d1: std_ulogic := '0';
begin
    Q <= ff_d0 when DDR = '0' else ff_d1;

    process(CLK)
    begin
        if rising_edge(CLK) then
            ff_d0 <= D0;
        end if;
        if falling_edge(CLK) then
            ff_d1 <= D1;
        end if;
    end process;
end sim;
