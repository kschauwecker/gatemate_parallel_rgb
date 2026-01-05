library synth;
context synth.synth_context;

-- Handles the physical output of the parallel RGB signals

entity rgb_output_stage is
    generic (
        PARALLEL_PIXELS: integer;                   -- 1 or 2; Must be 2 for 1080p to meet timing
        INVERT_RGB_CLK: boolean := false;           -- Inverts rgb_clk if true
        DIFF_RGB_CLK: boolean := true;              -- Choose between differential and single ended clock output

        -- Optional signals for differential clock output
        DIFF_CLK_PIN_NAME_P: string := "UNPLACED";  -- IO_<Dir><Bank>_<Pin><Pin#>
        DIFF_CLK_PIN_NAME_N: string := "UNPLACED";  -- secondary diff. signal
        DIFF_CLK_V_IO      : string := "UNDEFINED"  -- "1.8" or "2.5" Volt
    );
    port (
        -- Async reset signal
        usr_reset_n: in std_ulogic;

        -- Parallel RGB output signals
        rgb_clk_p: out std_ulogic;
        rgb_clk_n: out std_ulogic; -- Not used if DIFF_RGB_CLK=false
        rgb_data: out std_ulogic_vector(23 downto 0);
        rgb_de: out std_ulogic;
        rgb_hsync: out std_ulogic;
        rgb_vsync: out std_ulogic;

        -- Input signals
        input_data_clk: in std_ulogic;
        input_rgb_clk: in std_ulogic;
        input_de: in std_ulogic;
        input_hsync: in std_ulogic;
        input_vsync: in std_ulogic;
        input_data: in std_ulogic_vector(PARALLEL_PIXELS*24-1 downto 0)
    );
end rgb_output_stage;

architecture rtl of rgb_output_stage is
    component CC_ODDR is
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
    end component;

    component CC_LVDS_OBUF is
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
    end component;

    signal input_de_ddr: std_ulogic;
    signal input_hsync_ddr: std_ulogic;
    signal input_vsync_ddr: std_ulogic;
    signal input_data_ddr: std_ulogic_vector(23 downto 0);
begin
    -- Dual pixel output mode using DDR
    dual_pixel: if PARALLEL_PIXELS = 2 generate
        -- Clocking options: diff/single, invert/non-invert
        dual_diff_clk: if DIFF_RGB_CLK generate
            o_clk_diff: component CC_LVDS_OBUF
                generic map(
                    PIN_NAME_P => DIFF_CLK_PIN_NAME_P,
                    PIN_NAME_N => DIFF_CLK_PIN_NAME_N,
                    V_IO => DIFF_CLK_V_IO
                )
                port map (
                    A => select_constant(INVERT_RGB_CLK, not input_rgb_clk, input_rgb_clk),
                    O_P => rgb_clk_p,
                    O_N => rgb_clk_n
                );
        else generate
            o_clk_signle: component CC_ODDR
                port map (
                    D0 => select_constant(INVERT_RGB_CLK, not input_rgb_clk, input_rgb_clk),
                    D1 => select_constant(INVERT_RGB_CLK, not input_rgb_clk, input_rgb_clk),
                    CLK => input_data_clk,
                    DDR  => input_data_clk,
                    Q => rgb_clk_p
                );
            rgb_clk_n <= '0';
        end generate;

        o_de: component CC_ODDR
            port map (
                D0 => input_de,
                D1 => input_de_ddr,
                CLK => input_data_clk,
                DDR  => input_data_clk,
                Q => rgb_de
            );

        o_hsync: component CC_ODDR
            port map (
                D0 => input_hsync,
                D1 => input_hsync_ddr,
                CLK => input_data_clk,
                DDR  => input_data_clk,
                Q => rgb_hsync
            );

        o_vsync: component CC_ODDR
            port map (
                D0 => input_vsync,
                D1 => input_vsync_ddr,
                CLK => input_data_clk,
                DDR  => input_data_clk,
                Q => rgb_vsync
            );

        o_data: for i in 23 downto 0 generate
            o_rgb: component CC_ODDR
                port map (
                    D0 => input_data(i) and input_de,
                    D1 => input_data_ddr(i) and input_de_ddr,
                    CLK => input_data_clk,
                    DDR  => input_data_clk,
                    Q => rgb_data(i)
                );
        end generate;

        -- Output second clock cycle for DDR data
        process(input_data_clk, usr_reset_n)
        begin
            if usr_reset_n = '0' then
                input_data_ddr <= (others => '0');
                input_de_ddr <= '0';
                input_hsync_ddr <= '0';
                input_vsync_ddr <= '0';
            elsif falling_edge(input_data_clk) then
                input_data_ddr <= input_data(47 downto 24);
                input_de_ddr <= input_de;
                input_hsync_ddr <= input_hsync;
                input_vsync_ddr <= input_vsync;
            end if;
        end process;
    end generate;

    -- Single pixel output mode does not require DDR
    single_pixel: if PARALLEL_PIXELS = 1 generate
        rgb_data <= input_data when input_de='1' else (others => '0');

        single_diff_clk: if DIFF_RGB_CLK generate
            o_clk: component CC_LVDS_OBUF
                generic map(
                    PIN_NAME_P => DIFF_CLK_PIN_NAME_P,
                    PIN_NAME_N => DIFF_CLK_PIN_NAME_N,
                    V_IO => DIFF_CLK_V_IO
                )
                port map (
                    A => select_constant(INVERT_RGB_CLK, not input_rgb_clk, input_rgb_clk),
                    O_P => rgb_clk_p,
                    O_N => rgb_clk_n
                );
        else generate
            rgb_clk_p <= not input_rgb_clk when INVERT_RGB_CLK else input_rgb_clk;
            rgb_clk_n <= '0';
        end generate;

        rgb_vsync <= input_vsync;
        rgb_hsync <= input_hsync;
        rgb_de <= input_de;
    end generate;
end rtl;
