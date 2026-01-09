#TODO

#set clock_period   1000.0 / 148.5
#
## DDR timing requirements
#set dv_bre              0.9;             # Data valid before the rising clock edge
#set dv_are              1.0;             # Data valid after the rising clock edge
#set dv_bfe              0.9;             # Data valid before the falling clock edge
#set dv_afe              1.0;             # Data valid after the falling clock edge
#
## Single edge mode
##set dv_bre              1.2;             # Data valid before the rising clock edge
##set dv_are              1.3;             # Data valid after the rising clock edge
#
#set rgb_ports rgb_data* rgb_de rgb_hsync rgb_vsync
#
#set_output_delay -clock [get_clocks rgb.output_stage.input_rgb_clk] -max [expr $clock_period/2 - $dv_bfe] [get_ports $rgb_ports];
#set_output_delay -clock [get_clocks rgb.output_stage.input_rgb_clk] -min $dv_are                          [get_ports $rgb_ports];
#set_output_delay -clock [get_clocks rgb.output_stage.input_rgb_clk] -max [expr $clock_period/2 - $dv_bre] [get_ports $rgb_ports] -clock_fall -add_delay;
#set_output_delay -clock [get_clocks rgb.output_stage.input_rgb_clk] -min $dv_afe                          [get_ports $rgb_ports] -clock_fall -add_delay;

# Clock frequency = 148.5 Mhz; clock period = 6.734 ns
#set_output_delay -clock rgb.output_stage.input_rgb_clk -min 1.0 [get_ports rgb_data* rgb_de rgb_hsync rgb_vsync] -clock_fall -add_delay