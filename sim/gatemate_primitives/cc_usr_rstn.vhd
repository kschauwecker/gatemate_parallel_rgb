library sim;
context sim.sim_context;

entity CC_USR_RSTN is
    port (
        USR_RSTN: out std_ulogic
    );
end entity;

architecture sim of CC_USR_RSTN is
begin
    USR_RSTN <= '0', '1' after 100 ns;
end sim;
