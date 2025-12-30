context sim_context is
    use std.env.all;
    use std.textio.all;

    library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    library sim_lib;
    use sim_lib.sim_lib.all;

    library synth_lib;
    use synth_lib.synth_lib.all;

    library synth;

    --library sim;
    -- use sim.components.all;
end context;
