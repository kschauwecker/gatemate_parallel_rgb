library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

------------------------------------------------------
-- Common definitions that are used in simulation only
------------------------------------------------------

package sim_lib is
    procedure clock(signal clk: out std_logic; constant freq: integer);

    -- Generates a random signal that changes with the rising clock edge
    procedure random_sig(
        signal clk: in std_logic;
        signal sig: out std_logic;
        constant max_1_time: time;
        constant max_0_time: time;
        constant seed1: positive := 1;
        constant seed2: positive := 1
    );

    -- Convert a std_ulogic_vector to / from a hex string
    function from_hstring(str: string) return std_ulogic_vector;

    -- Writes a single register value through the AXI-lite bus
    procedure write_axi_register(
        constant address: in integer;
        variable data: in std_logic_vector;

        signal clk: in std_logic;
        signal awaddr: out std_logic_vector;
        signal awvalid: out std_logic;
        signal awready: in std_logic;
        signal wdata: out std_logic_vector;
        signal wvalid: out std_logic;
        signal wready: in std_logic);

    -- Reads a single register value through the AXI-lite bus
    procedure read_axi_register(
        constant address: in integer;
        variable data: out std_logic_vector;

        signal clk: in std_logic;
        signal araddr: out std_logic_vector;
        signal arvalid: out std_logic;
        signal arready: in std_logic;
        signal rdata: in std_logic_vector;
        signal rvalid: in std_logic;
        signal rready: in std_logic);
end sim_lib;

package body sim_lib is

    procedure clock(signal clk: out std_logic; constant freq: integer) is
        constant PERIOD: time := 1e9 ns / freq;
    begin
        loop
            clk <= '1';
            wait for PERIOD/2;

            clk <= '0';
            wait for PERIOD/2;
        end loop;
    end clock;

    ----------------------------------------------------------------------

    procedure random_sig (
        signal clk: in std_logic;
        signal sig: out std_logic;
        constant max_1_time: time;
        constant max_0_time: time;
        constant seed1: positive := 1;
        constant seed2: positive := 1
    ) is
        variable rand_seed1: positive := seed1;
        variable rand_seed2: positive := seed2;
        variable rand: real;
    begin
        loop
            if max_1_time = 0 ns then
                sig <= '0';
            elsif max_0_time = 0 ns then
                sig <= '1';
            else
                sig <= '1';
                uniform(rand_seed1, rand_seed2, rand);
                wait for rand*max_1_time;
                wait until clk'event and clk = '1';

                sig <= '0';
                uniform(rand_seed1, rand_seed2, rand);
                wait for rand*max_0_time;
            end if;

            wait until clk'event and clk = '1';
        end loop;
    end random_sig;

    ----------------------------------------------------------------------

    function from_hstring(str: string) return std_ulogic_vector is
        variable result: std_ulogic_vector (str'length*4-1 downto 0);
        variable hex_digit: character;
    begin
        for i in 0 to str'length-1 loop
            hex_digit := str(str'high - i);
            case hex_digit is
                when '0' => result((i+1)*4-1 downto i*4) := "0000";
                when '1' => result((i+1)*4-1 downto i*4) := "0001";
                when '2' => result((i+1)*4-1 downto i*4) := "0010";
                when '3' => result((i+1)*4-1 downto i*4) := "0011";
                when '4' => result((i+1)*4-1 downto i*4) := "0100";
                when '5' => result((i+1)*4-1 downto i*4) := "0101";
                when '6' => result((i+1)*4-1 downto i*4) := "0110";
                when '7' => result((i+1)*4-1 downto i*4) := "0111";
                when '8' => result((i+1)*4-1 downto i*4) := "1000";
                when '9' => result((i+1)*4-1 downto i*4) := "1001";
                when 'a' => result((i+1)*4-1 downto i*4) := "1010";
                when 'b' => result((i+1)*4-1 downto i*4) := "1011";
                when 'c' => result((i+1)*4-1 downto i*4) := "1100";
                when 'd' => result((i+1)*4-1 downto i*4) := "1101";
                when 'e' => result((i+1)*4-1 downto i*4) := "1110";
                when 'f' => result((i+1)*4-1 downto i*4) := "1111";
                when 'U' => result((i+1)*4-1 downto i*4) := "UUUU";
                when 'X' => result((i+1)*4-1 downto i*4) := "XXXX";
                when 'Z' => result((i+1)*4-1 downto i*4) := "ZZZZ";
                when 'W' => result((i+1)*4-1 downto i*4) := "WWWW";
                when 'L' => result((i+1)*4-1 downto i*4) := "LLLL";
                when 'H' => result((i+1)*4-1 downto i*4) := "HHHH";
                when '-' => result((i+1)*4-1 downto i*4) := "----";
                when others => result((i+1)*4-1 downto i*4) := "XXXX";
            end case;
       end loop;
       return result;
    end;

    ----------------------------------------------------------------------

    procedure write_axi_register(
        constant address: in integer;
        variable data: in std_logic_vector;

        signal clk: in std_logic;
        signal awaddr: out std_logic_vector;
        signal awvalid: out std_logic;
        signal awready: in std_logic;
        signal wdata: out std_logic_vector;
        signal wvalid: out std_logic;
        signal wready: in std_logic) is
    begin
        awaddr <= std_logic_vector(to_unsigned(address, awaddr'length));
        awvalid <= '1';
        wait until rising_edge(clk) and awready = '1';
        awvalid <= '0';
        wait until rising_edge(clk);

        wvalid <= '1';
        wdata <= data;
        wait until rising_edge(clk) and wready = '1';
        wvalid <= '0';
        wait until rising_edge(clk);
    end;

    ----------------------------------------------------------------------

    procedure read_axi_register(
        constant address: in integer;
        variable data: out std_logic_vector;

        signal clk: in std_logic;
        signal araddr: out std_logic_vector;
        signal arvalid: out std_logic;
        signal arready: in std_logic;
        signal rdata: in std_logic_vector;
        signal rvalid: in std_logic;
        signal rready: in std_logic) is
    begin
        araddr <= std_logic_vector(to_unsigned(address, araddr'length));
        arvalid <= '1';
        wait until rising_edge(clk) and arready = '1';
        arvalid <= '0';

        wait until rising_edge(clk) and rvalid = '1' and rready = '1';
        data := rdata;
    end;
end sim_lib;
