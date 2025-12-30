library sim;
context sim.sim_context;

entity CC_PLL is
    generic (
        REF_CLK         : string;  -- reference input in MHz
        OUT_CLK         : string;  -- pll output frequency in MHz
        PERF_MD         : string;  -- LOWPOWER, ECONOMY, SPEED
        LOW_JITTER      : integer; -- 0: disable, 1: enable low jitter mode
        CI_FILTER_CONST : integer; -- optional CI filter constant
        CP_FILTER_CONST : integer  -- optional CP filter constant
    );
    port (
        CLK_REF             : in  std_ulogic;
        USR_CLK_REF         : in  std_ulogic;
        CLK_FEEDBACK        : in  std_ulogic;
        USR_LOCKED_STDY_RST : in  std_ulogic;
        USR_PLL_LOCKED_STDY : out std_ulogic;
        USR_PLL_LOCKED      : out std_ulogic;
        CLK0                : out std_ulogic;
        CLK90               : out std_ulogic;
        CLK180              : out std_ulogic;
        CLK270              : out std_ulogic;
        CLK_REF_OUT         : out std_ulogic
    );
end entity;

architecture sim of CC_PLL is
    constant DELAY_90: time := 250 ns / real'value(OUT_CLK);
begin
    -- A simple simulation model of the PLL
    -- Not verified against the hardware or Cologne Chips implementation

    clock(CLK0, integer(real'value(OUT_CLK)*1.0e6));
    CLK90  <= CLK0 after DELAY_90;
    CLK180 <= CLK90 after DELAY_90;
    CLK270 <= CLK180 after DELAY_90;

    CLK_REF_OUT <= CLK_REF;
    USR_PLL_LOCKED <= '0', '1' after 200 ns;
    USR_PLL_LOCKED_STDY <= USR_PLL_LOCKED;
end sim;