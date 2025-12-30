library sim;
context sim.sim_context;

entity CC_BUFG is
    port (
        I: in  std_ulogic;
        O: out  std_ulogic
    );
end entity;

architecture sim of CC_BUFG is
begin
    O <= I;
end sim;