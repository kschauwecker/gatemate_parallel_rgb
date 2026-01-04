library sim;
context sim.sim_context;

-- Toplevel entitity of the design
entity toplevel_tb is
end toplevel_tb;

architecture rtl of toplevel_tb is
    component toplevel is
        port (
            ref_clk: in std_ulogic;
            led: out std_ulogic;

            rgb_clk_p: out std_ulogic;
            rgb_clk_n: out std_ulogic;
            rgb_data: out std_ulogic_vector(23 downto 0);
            rgb_de: out std_ulogic;
            rgb_hsync: out std_ulogic;
            rgb_vsync: out std_ulogic;

            pmod: out std_ulogic_vector(7 downto 0)
        );
    end component;

    signal ref_clk: std_ulogic;
    signal led: std_ulogic;

    signal rgb_clk_p: std_ulogic;
    signal rgb_clk_n: std_ulogic;
    signal rgb_data: std_ulogic_vector(23 downto 0);
    signal rgb_de: std_ulogic;
    signal rgb_hsync: std_ulogic;
    signal rgb_vsync: std_ulogic;
begin
    clock(ref_clk, 25e6); -- 25 MHz reference clock

    dut: component toplevel
        port map(
            ref_clk => ref_clk,
            led => led,

            rgb_clk_p => rgb_clk_p,
            rgb_clk_n => rgb_clk_n,
            rgb_data => rgb_data,
            rgb_de => rgb_de,
            rgb_hsync => rgb_hsync,
            rgb_vsync => rgb_vsync,

            pmod => open
        );

    process(rgb_clk_p)
        variable first_frame: std_ulogic := '1';
        variable vsync_buf: std_ulogic;
        variable start_of_frame: time;
        variable frame_started: std_ulogic := '0';

        variable screen_width: integer := 0;
        variable x_counter: integer := 0;
        variable y_counter: integer := 0;
    begin
        if rising_edge(rgb_clk_p) then
            if vsync_buf = '1' and rgb_vsync = '0' and frame_started = '0' then
                if first_frame = '0' then
                    print(time'image(now) & " FPS: " & to_string(1.0e9 / real(now / 1 ns -start_of_frame / 1 ns), "%.4f"));
                end if;

                frame_started := '1';
                start_of_frame := now;
                print(time'image(now) & " Start of frame");
            elsif vsync_buf = '0' and rgb_vsync = '1' and frame_started = '1' then
                frame_started := '0';
                first_frame := '0';
                print(time'image(now) & " End of frame");
                print(time'image(now) & " Screen size: " & to_string(screen_width) & " x " & to_string(y_counter));
                screen_width := 0;
                y_counter := 0;
            end if;

            -- Count screen size
            if frame_started = '1' then
                if rgb_de = '1' then
                    x_counter:= x_counter + 1;
                end if;
                if rgb_hsync = '1' and x_counter /= 0 then
                    if screen_width /= 0 and screen_width /= x_counter then
                        report "Row width mismatch. Current row: " & to_string(x_counter) & "; previously: "
                            & to_string(screen_width) severity failure;
                    end if;
                    if screen_width = 0 then
                        screen_width := x_counter;
                    end if;
                    x_counter := 0;
                    y_counter := y_counter + 1;
                end if;
            end if;

            vsync_buf := rgb_vsync;
        end if;
    end process;
end rtl;
