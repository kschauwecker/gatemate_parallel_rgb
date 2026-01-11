# Simulates a synthesized netlist using

set OSS_CAD_DIR [lindex $argv 0]
set SRC_DIR [lindex $argv 1]

# Initialize project
set _xil_proj_name_ "xsim"
create_project ${_xil_proj_name_} . -force
set_property SOURCE_SET sources_1 [get_filesets sim_1]

# Add testbench sources
set files [list \
    [file normalize "../sim/common/context.vhd"] \
    [file normalize "../sim/testbenches/toplevel_tb.vhd"] \
]
set added [add_files -fileset sim_1 -norecurse $files]
set_property LIBRARY "sim" $added

# Add simulation library
set files [list \
    [file normalize "../sim_lib/sim_lib.vhd"] \
]
set added [add_files -fileset sim_1 -norecurse $files]
set_property LIBRARY "sim_lib" $added

# Add synthesis library
set files [list \
    [file normalize "../synth_lib/synth_lib.vhd"] \
]
set added [add_files -fileset sim_1 -norecurse $files]
set_property LIBRARY "synth_lib" $added

# Add synthesized design and cell library
set files [list \
    [file normalize "$SRC_DIR/build/impl/toplevel_impl.v"] \
]
# For synthesis netlist simulation add: $OSS_CAD_DIR/share/yosys/gatemate/cells_sim.v
set added [add_files -fileset sim_1 -norecurse $files]

# Add simulation models for black box cells
set files [list \
    [file normalize "../sim/gatemate_primitives/cc_pll.vhd"] \
    [file normalize "../sim/gatemate_primitives/cc_usr_rstn.vhd"] \
]
set added [add_files -fileset sim_1 -norecurse $files]

# Enable VHDL2008 for all VHDL files
set_property FILE_TYPE {VHDL 2008} [get_files -filter {NAME =~ "*.vhd"}]

# Enable logging of all signals
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

# Enable timing simulation
set_property -name {xsim.elaborate.xelab.more_options} -value "-maxdelay -sdfmax dut=$SRC_DIR/build/impl/delays.sdf" -objects [get_filesets sim_1]

update_compile_order -fileset sim_1

launch_simulation
