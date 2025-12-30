library synth;
context synth.synth_context;

-- Toplevel entitity of the design
entity toplevel is
    port (
        ref_clk: in std_ulogic;
        led: out std_ulogic
    );
end toplevel;

architecture rtl of toplevel is
    -- Components for FPGA hard IP
    component CC_PLL is
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
    end component;

    component CC_BUFG is
        port (
            I: in  std_ulogic;
            O: out  std_ulogic
        );
    end component;

    component CC_USR_RSTN is
        port (
            USR_RSTN: out std_ulogic
        );
    end component;

    signal clk_pll: std_ulogic;
    signal usr_resetn: std_ulogic;
    signal reset_pll: std_ulogic;
    signal counter: unsigned(26 downto 0);
begin

    -- Reset signal
    rst: component CC_USR_RSTN
        port map (
            USR_RSTN => usr_resetn
        );

    -- Generate main clock through PLL
    pll: component CC_PLL
        generic map (
            REF_CLK         => "25.0",
            OUT_CLK         => "100.0",
            PERF_MD         => "ECONOMY",
            LOW_JITTER      => 1,
            CI_FILTER_CONST => 2,
            CP_FILTER_CONST => 4
        )
        port map (
            CLK_REF             => ref_clk,
            USR_CLK_REF         => '0',
            CLK_FEEDBACK        => '0',
            USR_LOCKED_STDY_RST => '0',
            USR_PLL_LOCKED_STDY => open,
            USR_PLL_LOCKED      => open,
            CLK0                => clk_pll,
            CLK90               => open,
            CLK180              => open,
            CLK270              => open,
            CLK_REF_OUT         => open
        );

    process(clk_pll)
        variable usr_resetn_sync: std_ulogic;
    begin
        if rising_edge(clk_pll) then
            reset_pll <= not usr_resetn_sync;
            usr_resetn_sync := usr_resetn;

            if reset_pll = '1' then
                counter <= (others => '0');
                led <= '0';
            else
                led <= counter(24);
                counter <= counter + 1;
            end if;
        end if;
    end process;
end rtl;
