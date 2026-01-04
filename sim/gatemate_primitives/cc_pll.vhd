library sim;
context sim.sim_context;

entity CC_PLL is
    generic (
        REF_CLK         : string := "0.0";  -- reference input in MHz
        OUT_CLK         : string := "0.0";  -- pll output frequency in MHz
        PERF_MD         : string := "UNDEFINED";  -- LOWPOWER, ECONOMY, SPEED
        LOW_JITTER      : integer := 1; -- 0: disable, 1: enable low jitter mode
        LOCK_REQ        : integer := 1; -- Lock status required before PLL output enable
        CLK270_DOUB     : integer := 0; -- Frequency doubling of CLOCK_270 PLL output
        CLK180_DOUB     : integer := 0; -- Frequency doubling of CLOCK_180 PLL output
        CI_FILTER_CONST : integer := 2; -- optional CI filter constant
        CP_FILTER_CONST : integer := 2  -- optional CP filter constant
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
    signal double_clock: std_ulogic;
begin
    -- A simple simulation model of the PLL
    -- Not verified against the hardware or Cologne Chips implementation

    gen_double: if CLK180_DOUB = 1 or CLK270_DOUB = 1 generate
        clock(double_clock, integer(real'value(OUT_CLK)*2.0e6));

        process(double_clock)
            variable clk_state: std_ulogic := '0';
        begin
            if rising_edge(double_clock) then
                clk_state := not clk_state;
                CLK0 <= clk_state;
            end if;
        end process;
    else generate
        clock(CLK0, integer(real'value(OUT_CLK)*1.0e6));
    end generate;

    CLK90  <= CLK0 after DELAY_90;

    CLK180 <= double_clock when CLK180_DOUB = 1
        else CLK90 after DELAY_90;

    CLK270 <= not double_clock when CLK270_DOUB = 1
         else (not CLK0) after DELAY_90;

    CLK_REF_OUT <= CLK_REF;
    USR_PLL_LOCKED <= '0', '1' after 200 ns;
    USR_PLL_LOCKED_STDY <= USR_PLL_LOCKED;
end sim;