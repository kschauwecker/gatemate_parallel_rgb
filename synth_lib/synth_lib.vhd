library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

-------------------------------------------------
-- Common definitions that are used in synthesis
-------------------------------------------------

package synth_lib is
    -------------------------------------------------
    -- Math functions
    -------------------------------------------------

    function log2(val: integer) return natural;

    -- Helper function for conditional constant assignment
    function select_constant(cond: boolean; if_true, if_false: integer) return integer;
    function select_constant(cond: boolean; if_true, if_false: std_ulogic_vector) return std_ulogic_vector;

    -------------------------------------------------
    -- IO functions
    -------------------------------------------------

    procedure print(str: string);

end synth_lib;

package body synth_lib is

    function log2(val: integer) return natural is
        variable res : natural;
    begin
        for i in 0 to 31 loop
            if (val <= (2**i)) then
                    res := i;
                exit;
            end if;
        end loop;
        return res;
    end;

    ----------------------------------------------------------------------

    procedure print(str: string) is
        variable ln: line;
    begin
        write(ln, str);
        writeline(output, ln);
    end;

    ----------------------------------------------------------------------

    function select_constant(cond: boolean; if_true, if_false: integer) return integer is
    begin
        if cond then
            return if_true;
        else
            return if_false;
        end if;
    end;

    ----------------------------------------------------------------------

    function select_constant(cond: boolean; if_true, if_false: std_ulogic_vector) return std_ulogic_vector is
    begin
        if cond then
            return if_true;
        else
            return if_false;
        end if;
    end;
end synth_lib;
