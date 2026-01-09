library synth;
context synth.synth_context;

-- Handles the physical output of the parallel RGB signals

entity rgb_output_stage is
    generic (
        PIXELS_PER_CLOCK: integer;                  -- 1 or 2; must be 2 for 1080p to meet timing
        INVERT_RGB_CLK: boolean := false;           -- Inverts rgb_clk if true
        DIFF_RGB_CLK: boolean := true;              -- Choose between differential and single ended clock output
        PIXEL_BUS_WIDTH: integer := 24;             -- 12 or 24; if 12 then DDR output will be used (reqires PIXELS_PER_CLOCK=2)

        -- Optional signals for differential clock output
        DIFF_CLK_PIN_NAME_P: string := "UNPLACED";  -- IO_<Dir><Bank>_<Pin><Pin#>
        DIFF_CLK_PIN_NAME_N: string := "UNPLACED";  -- secondary diff. signal
        DIFF_CLK_V_IO      : string := "UNDEFINED"  -- "1.8" or "2.5" Volt
    );
    port (
        -- Parallel RGB output signals
        rgb_clk_p: out std_ulogic;
        rgb_clk_n: out std_ulogic; -- Not used if DIFF_RGB_CLK=false
        rgb_data: out std_ulogic_vector(PIXEL_BUS_WIDTH-1 downto 0);
        rgb_de: out std_ulogic;
        rgb_hsync: out std_ulogic;
        rgb_vsync: out std_ulogic;

        -- Input signals
        input_data_clk: in std_ulogic;
        input_rgb_clk: in std_ulogic;
        input_de: in std_ulogic;
        input_hsync: in std_ulogic;
        input_vsync: in std_ulogic;
        input_data: in std_ulogic_vector(PIXELS_PER_CLOCK*24-1 downto 0)
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

    signal input_de_ddr1: std_ulogic;
    signal input_hsync_ddr1: std_ulogic;
    signal input_vsync_ddr1: std_ulogic;

    signal input_de_ddr0: std_ulogic;
    signal input_hsync_ddr0: std_ulogic;
    signal input_vsync_ddr0: std_ulogic;

    signal input_data_ddr1: std_ulogic_vector(23 downto 0);

    signal sync: std_ulogic := '0';
    signal sync_ddr0: std_ulogic := '0';
    signal sync_ddr1: std_ulogic := '0';

    signal ddr_data0: std_ulogic_vector(11 downto 0);
    signal ddr_data1: std_ulogic_vector(11 downto 0);
    signal ddr_buf0: std_ulogic_vector(11 downto 0);
    signal ddr_buf1: std_ulogic_vector(11 downto 0);
begin
    assert PIXEL_BUS_WIDTH=12 or PIXEL_BUS_WIDTH=24 severity failure;
    assert PIXELS_PER_CLOCK=1 or PIXELS_PER_CLOCK=2 severity failure;

    -- Generate clock output
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
        rgb_clk_p <= not input_rgb_clk when INVERT_RGB_CLK else input_rgb_clk;
        rgb_clk_n <= '0';
    end generate;

    -----------------------------------------------
    -- 12-bit DDR bus
    bus12_bit: if PIXEL_BUS_WIDTH=12 generate
        -- Output four bits from one input_data_clk clock cycle on two
        -- clock cycles of input_rgb_clk, using DDR

        assert PIXELS_PER_CLOCK = 2 severity failure; -- Not implemented yet

        -- Generate a synchronization signal to locate
        -- the rising edge of the data clock
        process(input_data_clk)
        begin
            if rising_edge(input_data_clk) then
                sync <= not sync;
            end if;
        end process;

        -- Split data over two DDR clock cycles
        process(input_rgb_clk)
        begin
            if rising_edge(input_rgb_clk) then
                if sync /= sync_ddr0 then
                    input_de_ddr0 <= input_de;
                    input_hsync_ddr0 <= input_hsync;
                    input_vsync_ddr0 <= input_vsync;
                    ddr_data0 <= input_data(11 downto 0);
                    ddr_buf0 <= input_data(35 downto 24);
                    sync_ddr0 <= sync;
                else
                    ddr_data0 <= ddr_buf0;
                end if;
            end if;

            if falling_edge(input_rgb_clk) then
                if sync /= sync_ddr1 then
                    input_de_ddr1 <= input_de;
                    input_hsync_ddr1 <= input_hsync;
                    input_vsync_ddr1 <= input_vsync;
                    ddr_data1 <= input_data(23 downto 12);
                    ddr_buf1 <= input_data(47 downto 36);
                    sync_ddr1 <= sync;
                else
                    ddr_data1 <= ddr_buf1;
                end if;
            end if;
        end process;

        -- DDR output buffers
        o_data: for i in 11 downto 0 generate
            o_rgb: component CC_ODDR
                port map (
                    D0 => ddr_data0(i),
                    D1 => ddr_data1(i),
                    CLK => input_rgb_clk,
                    DDR  => not input_rgb_clk,
                    Q => rgb_data(i)
                );
        end generate;

        o_de: component CC_ODDR
            port map (
                D0 => input_de_ddr0,
                D1 => input_de_ddr1,
                CLK => input_rgb_clk,
                DDR  => not input_rgb_clk,
                Q => rgb_de
            );

        o_hsync: component CC_ODDR
            port map (
                D0 => input_hsync_ddr0,
                D1 => input_hsync_ddr1,
                CLK => input_rgb_clk,
                DDR  => not input_rgb_clk,
                Q => rgb_hsync
            );

        o_vsync: component CC_ODDR
            port map (
                D0 => input_vsync_ddr0,
                D1 => input_vsync_ddr1,
                CLK => input_rgb_clk,
                DDR  => not input_rgb_clk,
                Q => rgb_vsync
            );
    end generate;

    -----------------------------------------------
    -- Dual pixel output mode using DDR
    dual_pixel: if PIXELS_PER_CLOCK = 2 and PIXEL_BUS_WIDTH=24 generate
        o_de: component CC_ODDR
            port map (
                D0 => input_de,
                D1 => input_de_ddr1,
                CLK => input_data_clk,
                DDR  => not input_data_clk,
                Q => rgb_de
            );

        o_hsync: component CC_ODDR
            port map (
                D0 => input_hsync,
                D1 => input_hsync_ddr1,
                CLK => input_data_clk,
                DDR  => not input_data_clk,
                Q => rgb_hsync
            );

        o_vsync: component CC_ODDR
            port map (
                D0 => input_vsync,
                D1 => input_vsync_ddr1,
                CLK => input_data_clk,
                DDR  => not input_data_clk,
                Q => rgb_vsync
            );

        o_data: for i in 23 downto 0 generate
            o_rgb: component CC_ODDR
                port map (
                    D0 => input_data(i),
                    D1 => input_data_ddr1(i),
                    CLK => input_data_clk,
                    DDR  => not input_data_clk,
                    Q => rgb_data(i)
                );
        end generate;

        -- Output second clock cycle for DDR data
        process(input_data_clk)
        begin
            if falling_edge(input_data_clk) then
                input_data_ddr1 <= input_data(47 downto 24);
                input_de_ddr1 <= input_de;
                input_hsync_ddr1 <= input_hsync;
                input_vsync_ddr1 <= input_vsync;
            end if;
        end process;
    end generate;

    -----------------------------------------------
    -- Simple single pixel output mode does not require DDR
    single_pixel: if PIXELS_PER_CLOCK = 1 generate
        rgb_data <= input_data when input_de='1' else (others => '0');
        rgb_vsync <= input_vsync;
        rgb_hsync <= input_hsync;
        rgb_de <= input_de;
    end generate;
end rtl;
